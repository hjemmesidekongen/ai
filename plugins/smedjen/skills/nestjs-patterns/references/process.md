# NestJS Patterns — Process Reference

## Module Patterns

### Feature Module
Each domain gets its own module. Own your providers; import only what you need.

```typescript
@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [UsersController],
  providers: [UsersService, UsersRepository],
  exports: [UsersService], // only export what other modules legitimately need
})
export class UsersModule {}
```

### Shared Module
Reusable, stateless utilities. Marked `@Global()` only when re-importing everywhere would be noise (e.g., ConfigModule).

```typescript
@Global()
@Module({
  providers: [CryptoService, LoggerService],
  exports: [CryptoService, LoggerService],
})
export class SharedModule {}
```

### Dynamic Module
For configurable modules that need runtime options (DB connection strings, API keys).

```typescript
@Module({})
export class DatabaseModule {
  static forRoot(options: DatabaseOptions): DynamicModule {
    return {
      module: DatabaseModule,
      providers: [
        { provide: DATABASE_OPTIONS, useValue: options },
        DatabaseService,
      ],
      exports: [DatabaseService],
      global: true,
    };
  }
}
```

---

## Providers and Dependency Injection

Standard provider: class decorated with `@Injectable()`, registered in a module's `providers` array. NestJS handles instantiation and injection.

Custom providers for complex cases:
- `useValue` — inject a constant or mock
- `useFactory` — async factory, inject config at startup
- `useClass` — swap implementation based on environment
- `useExisting` — alias one token to another

```typescript
// Factory provider with async resolution
{
  provide: 'REDIS_CLIENT',
  useFactory: async (config: ConfigService) => {
    return await createRedisClient(config.get('REDIS_URL'));
  },
  inject: [ConfigService],
}
```

Inject with `@Inject('REDIS_CLIENT')` when the token is a string or symbol, not a class reference.

Scope defaults to `DEFAULT` (singleton per module). Use `REQUEST` scope only when you genuinely need per-request state — it forces all dependents into request scope and degrades performance.

---

## Controllers

Keep controllers thin. They translate HTTP to service calls, nothing more.

```typescript
@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get(':id')
  @Roles('admin', 'self')
  async findOne(@Param('id', ParseUUIDPipe) id: string, @CurrentUser() user: User) {
    return this.usersService.findById(id);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() dto: CreateUserDto) {
    return this.usersService.create(dto);
  }
}
```

---

## Guards

Guards determine whether a request proceeds. They run after middleware, before pipes and handlers.

### Auth Guard (JWT)

```typescript
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  canActivate(context: ExecutionContext) {
    // allow routes decorated with @Public() to skip auth
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;
    return super.canActivate(context);
  }
}
```

### Roles Guard

Runs after auth guard — relies on `user` already being attached to the request.

```typescript
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!requiredRoles?.length) return true;
    const { user } = context.switchToHttp().getRequest();
    return requiredRoles.some(role => user.roles.includes(role));
  }
}
```

Register global guards in AppModule providers:
```typescript
{ provide: APP_GUARD, useClass: JwtAuthGuard }
```

---

## Interceptors

Interceptors wrap handler execution. They run before AND after the handler, and can transform the response stream.

### Logging Interceptor

```typescript
@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger(LoggingInterceptor.name);

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const req = context.switchToHttp().getRequest();
    const start = Date.now();

    return next.handle().pipe(
      tap(() => {
        this.logger.log(`${req.method} ${req.url} — ${Date.now() - start}ms`);
      }),
    );
  }
}
```

### Transform Interceptor

Wrap all responses in a consistent envelope:

```typescript
@Injectable()
export class TransformInterceptor<T> implements NestInterceptor<T, Response<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<Response<T>> {
    return next.handle().pipe(
      map(data => ({ data, timestamp: new Date().toISOString() })),
    );
  }
}
```

### Cache Interceptor

Use `CacheInterceptor` from `@nestjs/cache-manager` for HTTP-level caching. Set `@CacheTTL()` per route; override global TTL when needed.

---

## Pipes

Pipes validate and/or transform input before it reaches the handler.

### Validation Pipe (global)

```typescript
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true,           // strip unknown properties
    forbidNonWhitelisted: true, // throw on unknown properties
    transform: true,           // auto-convert primitives to declared types
    transformOptions: { enableImplicitConversion: true },
  }),
);
```

### DTO with class-validator

```typescript
export class CreateUserDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  @MaxLength(72)
  password: string;

  @IsEnum(UserRole)
  @IsOptional()
  role?: UserRole;
}
```

### Custom Transform Pipe

```typescript
@Injectable()
export class ParsePositiveIntPipe implements PipeTransform<string, number> {
  transform(value: string): number {
    const val = parseInt(value, 10);
    if (isNaN(val) || val <= 0) {
      throw new BadRequestException(`${value} is not a positive integer`);
    }
    return val;
  }
}
```

---

## Exception Filters

Catch unhandled exceptions and return consistent error shapes.

```typescript
@Catch(HttpException)
export class HttpExceptionFilter implements ExceptionFilter {
  catch(exception: HttpException, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const status = exception.getStatus();
    const exceptionResponse = exception.getResponse();

    response.status(status).json({
      statusCode: status,
      timestamp: new Date().toISOString(),
      message: typeof exceptionResponse === 'object'
        ? (exceptionResponse as any).message
        : exceptionResponse,
    });
  }
}
```

Register globally: `app.useGlobalFilters(new HttpExceptionFilter())`.

Catch `Error` (not `HttpException`) in a second filter for unhandled exceptions — map to 500 and log with full stack trace.

---

## Middleware

Middleware runs before guards. Use for: request logging, rate limiting, body parsing, JWT extraction (when not using Passport). Keep middleware stateless.

```typescript
@Injectable()
export class CorrelationIdMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    req['correlationId'] = req.headers['x-correlation-id'] || uuid();
    res.setHeader('x-correlation-id', req['correlationId']);
    next();
  }
}

// In AppModule:
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(CorrelationIdMiddleware).forRoutes('*');
  }
}
```

---

## Microservices Basics

NestJS supports TCP, Redis, NATS, Kafka transports out of the box.

```typescript
// Microservice app bootstrap
const app = await NestFactory.createMicroservice<MicroserviceOptions>(AppModule, {
  transport: Transport.REDIS,
  options: { host: 'localhost', port: 6379 },
});

// Message handler
@MessagePattern('user.created')
handleUserCreated(@Payload() data: UserCreatedEvent) {
  return this.usersService.onUserCreated(data);
}

// Event handler (fire-and-forget)
@EventPattern('order.shipped')
handleOrderShipped(@Payload() data: OrderShippedEvent) {
  this.notificationService.notify(data);
}
```

For hybrid apps (HTTP + microservice), use `app.connectMicroservice()` before `app.listen()`.

---

## Testing

### Unit Tests

```typescript
describe('UsersService', () => {
  let service: UsersService;
  let repo: jest.Mocked<UsersRepository>;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: UsersRepository,
          useValue: {
            findOne: jest.fn(),
            save: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get(UsersService);
    repo = module.get(UsersRepository);
  });

  it('throws NotFoundException when user not found', async () => {
    repo.findOne.mockResolvedValue(null);
    await expect(service.findById('123')).rejects.toThrow(NotFoundException);
  });
});
```

Mock at the boundary — never mock internals of the class under test.

### E2E Tests with Supertest

```typescript
describe('Users (e2e)', () => {
  let app: INestApplication;
  let accessToken: string;

  beforeAll(async () => {
    const module = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = module.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();

    // Auth setup
    const res = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'test@example.com', password: 'password' });
    accessToken = res.body.accessToken;
  });

  afterAll(() => app.close());

  it('GET /users/:id returns 404 for unknown user', () => {
    return request(app.getHttpServer())
      .get('/users/00000000-0000-0000-0000-000000000000')
      .set('Authorization', `Bearer ${accessToken}`)
      .expect(404);
  });
});
```

Use a separate test database. Seed via TypeORM fixtures or direct repo calls in `beforeAll`.

---

## CQRS Pattern

Use `@nestjs/cqrs` when command handlers grow complex or you need event sourcing foundations.

```typescript
// Command
export class CreateUserCommand {
  constructor(public readonly dto: CreateUserDto) {}
}

// Handler
@CommandHandler(CreateUserCommand)
export class CreateUserHandler implements ICommandHandler<CreateUserCommand> {
  constructor(private readonly repo: UsersRepository, private readonly bus: EventBus) {}

  async execute(command: CreateUserCommand) {
    const user = await this.repo.create(command.dto);
    this.bus.publish(new UserCreatedEvent(user.id));
    return user;
  }
}
```

CQRS adds indirection — only reach for it when command logic is complex enough to justify the seam (multiple side effects, event sourcing, distinct read/write models).

---

## Common Anti-Patterns

**Fat controllers**: business logic in handlers. Handlers should call one service method.

**Circular dependencies**: ModuleA imports ModuleB which imports ModuleA. Use `forwardRef()` as a temporary patch, but restructure to eliminate the cycle.

**Service reaching into other modules directly**: go through exported services, not internal repositories.

**Global mutable state in singleton services**: singletons are shared across requests. Any request-scoped data must live in the request object or a REQUEST-scoped provider.

**Skipping ValidationPipe whitelist**: without `whitelist: true`, unknown properties pass through to the handler — a security risk if they reach the DB.

**Over-using interceptors for business logic**: interceptors are cross-cutting concerns (logging, caching, response shaping). Business rules belong in services.

**Catching all exceptions in handlers with try/catch**: let exception filters handle it. Handlers should throw, not catch.
