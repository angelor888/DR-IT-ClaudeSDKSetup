# Model Switching Command

I'll help you switch between different Claude models and modes for optimal performance.

## Current Model Information

**Active Model**: ${CLAUDE_MODEL:-claude-opus-4}  
**Current Mode**: ${CLAUDE_MODE:-default}  
**Session Type**: ${CLAUDE_SESSION:-interactive}

## Available Models

### Claude Opus 4 (Default)
- **Best for**: Complex reasoning, code generation, analysis
- **Strengths**: Highest capability, best for difficult tasks
- **Use cases**: Architecture design, complex debugging, research

### Claude Sonnet 3.5
- **Best for**: Balanced performance and speed
- **Strengths**: Good reasoning with faster responses
- **Use cases**: General development, code review, documentation

### Claude Haiku 3.5
- **Best for**: Simple tasks, quick responses
- **Strengths**: Fast, efficient for straightforward tasks
- **Use cases**: Code formatting, simple questions, quick edits

## Mode Switching

### Default Mode
- Standard interactive mode
- Full context awareness
- Comprehensive responses

### Plan Mode (Shift+Tab Shift+Tab)
- Structured task planning
- Step-by-step execution
- User approval required

### Auto-Accept Mode
- Automatic execution of safe commands
- Reduced interaction for trusted operations
- Faster workflow for repetitive tasks

## Model Selection

Based on your request "$ARGUMENTS", I recommend:

$(echo "$ARGUMENTS" | grep -qi "complex\|architecture\|design\|analysis\|research\|difficult" && echo "🎯 **Claude Opus 4** - This task requires deep reasoning and analysis" || echo "")
$(echo "$ARGUMENTS" | grep -qi "quick\|simple\|format\|edit\|small" && echo "⚡ **Claude Haiku 3.5** - This is a straightforward task that can be completed quickly" || echo "")
$(echo "$ARGUMENTS" | grep -qi "review\|document\|general\|development" && echo "⚖️ **Claude Sonnet 3.5** - This requires balanced capability and speed" || echo "")

## Quick Switch Commands

### Model Switching
- `/model opus` - Switch to Claude Opus 4
- `/model sonnet` - Switch to Claude Sonnet 3.5  
- `/model haiku` - Switch to Claude Haiku 3.5

### Mode Switching
- `/mode default` - Standard interactive mode
- `/mode plan` - Enter planning mode
- `/mode auto` - Enable auto-accept mode

## Performance Optimization

### For Speed
1. Use Claude Haiku for simple tasks
2. Enable auto-accept mode for trusted operations
3. Use concise prompts

### For Quality
1. Use Claude Opus for complex reasoning
2. Enable plan mode for structured tasks
3. Provide detailed context

### For Balance
1. Use Claude Sonnet for most tasks
2. Switch models based on complexity
3. Use appropriate modes for workflow

## Current Session Settings

- **Model**: ${CLAUDE_MODEL:-claude-opus-4}
- **Mode**: ${CLAUDE_MODE:-default}
- **Plan Mode**: ${CLAUDE_PLAN_MODE:-disabled}
- **Auto-Accept**: ${CLAUDE_AUTO_ACCEPT:-disabled}
- **Voice Notifications**: ${CLAUDE_VOICE_ENABLED:-enabled}

Would you like me to switch to a different model or mode for your current task?