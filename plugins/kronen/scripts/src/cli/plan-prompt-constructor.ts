import { constructPlanPrompt } from '../utils/plan-prompt-constructor.ts';

const planDir = process.argv[2];
if (!planDir) {
  process.stderr.write('Usage: plan-prompt-constructor <plan-directory>\n');
  process.exit(1);
}
const prompt = constructPlanPrompt(planDir);
if (prompt) process.stdout.write(prompt + '\n');
