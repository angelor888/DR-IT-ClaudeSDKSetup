/**
 * Automated Code Review with Claude
 * Demonstrates building a code review automation tool
 */
import Anthropic from '@anthropic-ai/sdk';
import * as fs from 'fs/promises';
import * as path from 'path';

interface CodeReviewResult {
  file: string;
  issues: string[];
  suggestions: string[];
  score: number;
}

class CodeReviewer {
  private anthropic: Anthropic;

  constructor(apiKey?: string) {
    this.anthropic = new Anthropic({ apiKey });
  }

  async reviewCode(
    code: string,
    filename: string,
    context?: string
  ): Promise<CodeReviewResult> {
    const extension = path.extname(filename);
    const language = this.getLanguageFromExtension(extension);

    const prompt = `Review this ${language} code from file "${filename}".
${context ? `Context: ${context}\n` : ''}
Please provide:
1. List of potential issues (bugs, security concerns, performance)
2. Suggestions for improvement
3. Code quality score (1-10)
4. Brief summary

Code to review:
\`\`\`${language}
${code}
\`\`\`

Format your response as JSON with this structure:
{
  "issues": ["issue1", "issue2"],
  "suggestions": ["suggestion1", "suggestion2"],
  "score": 8,
  "summary": "Brief summary"
}`;

    const message = await this.anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 2048,
      temperature: 0.3,
      system: 'You are an expert code reviewer. Always respond with valid JSON.',
      messages: [{ role: 'user', content: prompt }],
    });

    try {
      const response = JSON.parse(message.content[0].text);
      return {
        file: filename,
        issues: response.issues || [],
        suggestions: response.suggestions || [],
        score: response.score || 0,
      };
    } catch (error) {
      console.error('Failed to parse response:', error);
      return {
        file: filename,
        issues: ['Failed to parse review response'],
        suggestions: [],
        score: 0,
      };
    }
  }

  async reviewFile(filePath: string): Promise<CodeReviewResult> {
    const code = await fs.readFile(filePath, 'utf-8');
    const filename = path.basename(filePath);
    return this.reviewCode(code, filename);
  }

  async reviewDirectory(
    dirPath: string,
    extensions: string[] = ['.ts', '.js', '.py']
  ): Promise<CodeReviewResult[]> {
    const results: CodeReviewResult[] = [];
    const files = await fs.readdir(dirPath);

    for (const file of files) {
      const filePath = path.join(dirPath, file);
      const stat = await fs.stat(filePath);

      if (stat.isFile() && extensions.includes(path.extname(file))) {
        console.log(`Reviewing ${file}...`);
        const result = await this.reviewFile(filePath);
        results.push(result);
      }
    }

    return results;
  }

  private getLanguageFromExtension(ext: string): string {
    const langMap: Record<string, string> = {
      '.ts': 'typescript',
      '.js': 'javascript',
      '.py': 'python',
      '.java': 'java',
      '.cpp': 'cpp',
      '.go': 'go',
      '.rs': 'rust',
    };
    return langMap[ext] || 'text';
  }

  generateReport(results: CodeReviewResult[]): string {
    let report = '# Code Review Report\n\n';
    let totalScore = 0;

    for (const result of results) {
      report += `## ${result.file}\n`;
      report += `**Score:** ${result.score}/10\n\n`;

      if (result.issues.length > 0) {
        report += '### Issues\n';
        result.issues.forEach((issue) => {
          report += `- ${issue}\n`;
        });
        report += '\n';
      }

      if (result.suggestions.length > 0) {
        report += '### Suggestions\n';
        result.suggestions.forEach((suggestion) => {
          report += `- ${suggestion}\n`;
        });
        report += '\n';
      }

      totalScore += result.score;
    }

    const avgScore = (totalScore / results.length).toFixed(1);
    report = `**Overall Score:** ${avgScore}/10\n\n` + report;

    return report;
  }
}

// Example usage
async function main() {
  const reviewer = new CodeReviewer();

  // Review a single code snippet
  const sampleCode = `
function processData(data) {
  let result = [];
  for (let i = 0; i < data.length; i++) {
    if (data[i] > 0) {
      result.push(data[i] * 2);
    }
  }
  return result;
}
`;

  console.log('Reviewing sample code...');
  const review = await reviewer.reviewCode(
    sampleCode,
    'sample.js',
    'This function processes an array of numbers'
  );

  console.log('\nReview Results:');
  console.log('Issues:', review.issues);
  console.log('Suggestions:', review.suggestions);
  console.log('Score:', review.score);

  // Review multiple files in a directory
  // const results = await reviewer.reviewDirectory('./src');
  // const report = reviewer.generateReport(results);
  // await fs.writeFile('code-review-report.md', report);
  // console.log('Report saved to code-review-report.md');
}

// Run if this file is executed directly
if (require.main === module) {
  main().catch(console.error);
}

export { CodeReviewer, CodeReviewResult };