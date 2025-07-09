#!/usr/bin/env bun
/**
 * TypeScript Interface Generator for Claude Code Logs
 * Automatically generates TypeScript interfaces from JSONL log files
 */

import { readFileSync, writeFileSync, existsSync } from 'fs';
import { join, dirname, basename } from 'path';

interface LogEntry {
    timestamp: string;
    session_id: string;
    tool: {
        name: string;
        arguments: string;
        working_directory: string;
    };
    execution: {
        status: string;
        exit_code: number;
        duration_ms: number;
        start_time: number;
        end_time: number;
    };
    output: {
        metrics: {
            lines: number;
            characters: number;
            words: number;
        };
        preview: string;
    };
    environment: {
        user: string;
        hostname: string;
        pid: number;
    };
    severity: string;
}

interface InterfaceGeneratorOptions {
    outputDir?: string;
    generateValidation?: boolean;
    includeComments?: boolean;
}

class LogInterfaceGenerator {
    private logFilePath: string;
    private options: InterfaceGeneratorOptions;

    constructor(logFilePath: string, options: InterfaceGeneratorOptions = {}) {
        this.logFilePath = logFilePath;
        this.options = {
            outputDir: options.outputDir || dirname(logFilePath),
            generateValidation: options.generateValidation ?? true,
            includeComments: options.includeComments ?? true,
        };
    }

    /**
     * Generate TypeScript interfaces from JSONL log file
     */
    public generateInterfaces(): void {
        if (!existsSync(this.logFilePath)) {
            console.error(`Log file not found: ${this.logFilePath}`);
            return;
        }

        try {
            const entries = this.parseLogEntries();
            const interfaces = this.createInterfaceDefinitions(entries);
            const validation = this.options.generateValidation ? this.createValidationFunctions(entries) : '';
            const utilities = this.createUtilityFunctions(entries);
            
            const outputContent = this.formatOutput(interfaces, validation, utilities);
            const outputPath = join(this.options.outputDir!, `${basename(this.logFilePath, '.jsonl')}-interfaces.ts`);
            
            writeFileSync(outputPath, outputContent);
            console.log(`Generated TypeScript interfaces: ${outputPath}`);
            
            // Generate summary report
            this.generateSummaryReport(entries, outputPath);
            
        } catch (error) {
            console.error(`Error generating interfaces: ${error}`);
        }
    }

    /**
     * Parse JSONL log entries
     */
    private parseLogEntries(): LogEntry[] {
        const content = readFileSync(this.logFilePath, 'utf-8');
        const lines = content.trim().split('\n').filter(line => line.trim());
        
        return lines.map((line, index) => {
            try {
                return JSON.parse(line) as LogEntry;
            } catch (error) {
                console.warn(`Invalid JSON at line ${index + 1}: ${line.substring(0, 50)}...`);
                return null;
            }
        }).filter(entry => entry !== null) as LogEntry[];
    }

    /**
     * Create TypeScript interface definitions
     */
    private createInterfaceDefinitions(entries: LogEntry[]): string {
        const tools = new Set(entries.map(e => e.tool.name));
        const statuses = new Set(entries.map(e => e.execution.status));
        const severities = new Set(entries.map(e => e.severity));

        return `
${this.options.includeComments ? '/**\n * Claude Code Tool Execution Log Entry\n * Generated automatically from log analysis\n */' : ''}
export interface ClaudeToolExecution {
    timestamp: string;
    session_id: string;
    tool: ToolInfo;
    execution: ExecutionResult;
    output: OutputMetrics;
    environment: EnvironmentInfo;
    severity: LogSeverity;
}

${this.options.includeComments ? '/** Tool information and arguments */' : ''}
export interface ToolInfo {
    name: ToolName;
    arguments: string;
    working_directory: string;
}

${this.options.includeComments ? '/** Execution timing and result information */' : ''}
export interface ExecutionResult {
    status: ExecutionStatus;
    exit_code: number;
    duration_ms: number;
    start_time: number;
    end_time: number;
}

${this.options.includeComments ? '/** Output size and content metrics */' : ''}
export interface OutputMetrics {
    metrics: {
        lines: number;
        characters: number;
        words: number;
    };
    preview: string;
}

${this.options.includeComments ? '/** System environment information */' : ''}
export interface EnvironmentInfo {
    user: string;
    hostname: string;
    pid: number;
}

${this.options.includeComments ? '/** Available Claude Code tools */' : ''}
export type ToolName = ${Array.from(tools).map(t => `'${t}'`).join(' | ')};

${this.options.includeComments ? '/** Execution status types */' : ''}
export type ExecutionStatus = ${Array.from(statuses).map(s => `'${s}'`).join(' | ')};

${this.options.includeComments ? '/** Log severity levels */' : ''}
export type LogSeverity = ${Array.from(severities).map(s => `'${s}'`).join(' | ')};
`;
    }

    /**
     * Create validation functions
     */
    private createValidationFunctions(entries: LogEntry[]): string {
        if (!this.options.generateValidation) return '';

        return `
${this.options.includeComments ? '/**\n * Validation functions for log entries\n */' : ''}
export class LogValidator {
    static isValidToolExecution(entry: any): entry is ClaudeToolExecution {
        return (
            typeof entry === 'object' &&
            typeof entry.timestamp === 'string' &&
            typeof entry.session_id === 'string' &&
            this.isValidToolInfo(entry.tool) &&
            this.isValidExecutionResult(entry.execution) &&
            this.isValidOutputMetrics(entry.output) &&
            this.isValidEnvironmentInfo(entry.environment) &&
            typeof entry.severity === 'string'
        );
    }

    static isValidToolInfo(tool: any): tool is ToolInfo {
        return (
            typeof tool === 'object' &&
            typeof tool.name === 'string' &&
            typeof tool.arguments === 'string' &&
            typeof tool.working_directory === 'string'
        );
    }

    static isValidExecutionResult(execution: any): execution is ExecutionResult {
        return (
            typeof execution === 'object' &&
            typeof execution.status === 'string' &&
            typeof execution.exit_code === 'number' &&
            typeof execution.duration_ms === 'number' &&
            typeof execution.start_time === 'number' &&
            typeof execution.end_time === 'number'
        );
    }

    static isValidOutputMetrics(output: any): output is OutputMetrics {
        return (
            typeof output === 'object' &&
            typeof output.metrics === 'object' &&
            typeof output.metrics.lines === 'number' &&
            typeof output.metrics.characters === 'number' &&
            typeof output.metrics.words === 'number' &&
            typeof output.preview === 'string'
        );
    }

    static isValidEnvironmentInfo(env: any): env is EnvironmentInfo {
        return (
            typeof env === 'object' &&
            typeof env.user === 'string' &&
            typeof env.hostname === 'string' &&
            typeof env.pid === 'number'
        );
    }
}
`;
    }

    /**
     * Create utility functions for log analysis
     */
    private createUtilityFunctions(entries: LogEntry[]): string {
        const avgDuration = entries.length > 0 
            ? Math.round(entries.reduce((sum, e) => sum + e.execution.duration_ms, 0) / entries.length)
            : 0;

        return `
${this.options.includeComments ? '/**\n * Utility functions for log analysis\n */' : ''}
export class LogAnalyzer {
    static parseLogFile(filePath: string): ClaudeToolExecution[] {
        // Implementation would read and parse JSONL file
        throw new Error('Implementation required');
    }

    static getExecutionStats(entries: ClaudeToolExecution[]): ExecutionStats {
        const totalExecutions = entries.length;
        const successfulExecutions = entries.filter(e => e.execution.status === 'success').length;
        const avgDuration = totalExecutions > 0
            ? entries.reduce((sum, e) => sum + e.execution.duration_ms, 0) / totalExecutions
            : 0;

        const toolUsage = entries.reduce((acc, e) => {
            acc[e.tool.name] = (acc[e.tool.name] || 0) + 1;
            return acc;
        }, {} as Record<string, number>);

        return {
            totalExecutions,
            successfulExecutions,
            successRate: totalExecutions > 0 ? successfulExecutions / totalExecutions : 0,
            avgDurationMs: Math.round(avgDuration),
            toolUsage
        };
    }

    static filterByTool(entries: ClaudeToolExecution[], toolName: ToolName): ClaudeToolExecution[] {
        return entries.filter(e => e.tool.name === toolName);
    }

    static filterByTimeRange(entries: ClaudeToolExecution[], startTime: Date, endTime: Date): ClaudeToolExecution[] {
        return entries.filter(e => {
            const entryTime = new Date(e.timestamp);
            return entryTime >= startTime && entryTime <= endTime;
        });
    }

    static getSlowExecutions(entries: ClaudeToolExecution[], thresholdMs: number = ${avgDuration * 2}): ClaudeToolExecution[] {
        return entries.filter(e => e.execution.duration_ms > thresholdMs);
    }

    static getFailedExecutions(entries: ClaudeToolExecution[]): ClaudeToolExecution[] {
        return entries.filter(e => e.execution.status === 'failure');
    }
}

export interface ExecutionStats {
    totalExecutions: number;
    successfulExecutions: number;
    successRate: number;
    avgDurationMs: number;
    toolUsage: Record<string, number>;
}
`;
    }

    /**
     * Format the complete output file
     */
    private formatOutput(interfaces: string, validation: string, utilities: string): string {
        const header = `/**
 * Claude Code Tool Execution Log Interfaces
 * Generated automatically from: ${basename(this.logFilePath)}
 * Generated at: ${new Date().toISOString()}
 * 
 * This file contains TypeScript interfaces and utilities for working
 * with Claude Code tool execution logs.
 */

`;

        return header + interfaces + validation + utilities;
    }

    /**
     * Generate a summary report
     */
    private generateSummaryReport(entries: LogEntry[], interfacePath: string): void {
        const stats = {
            totalEntries: entries.length,
            dateRange: entries.length > 0 ? {
                earliest: entries[0]?.timestamp,
                latest: entries[entries.length - 1]?.timestamp
            } : null,
            tools: [...new Set(entries.map(e => e.tool.name))],
            avgDuration: entries.length > 0
                ? Math.round(entries.reduce((sum, e) => sum + e.execution.duration_ms, 0) / entries.length)
                : 0,
            successRate: entries.length > 0
                ? Math.round((entries.filter(e => e.execution.status === 'success').length / entries.length) * 100)
                : 0
        };

        const reportPath = join(this.options.outputDir!, `${basename(this.logFilePath, '.jsonl')}-summary.md`);
        const reportContent = `# Log Analysis Summary

**Generated**: ${new Date().toISOString()}
**Source**: ${this.logFilePath}
**Interfaces**: ${interfacePath}

## Statistics
- **Total Entries**: ${stats.totalEntries}
- **Success Rate**: ${stats.successRate}%
- **Average Duration**: ${stats.avgDuration}ms
- **Tools Used**: ${stats.tools.length}

## Tool Usage
${stats.tools.map(tool => `- ${tool}`).join('\n')}

## Date Range
${stats.dateRange ? `- **Earliest**: ${stats.dateRange.earliest}\n- **Latest**: ${stats.dateRange.latest}` : '- No entries found'}
`;

        writeFileSync(reportPath, reportContent);
        console.log(`Generated summary report: ${reportPath}`);
    }
}

// Main execution
if (import.meta.main) {
    const logFilePath = process.argv[2];
    
    if (!logFilePath) {
        console.error('Usage: generate-log-interfaces.ts <log-file-path>');
        process.exit(1);
    }

    const generator = new LogInterfaceGenerator(logFilePath, {
        generateValidation: true,
        includeComments: true
    });

    generator.generateInterfaces();
}

export { LogInterfaceGenerator };