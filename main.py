import os
import sys
import subprocess
from crewai import Agent, Task, Crew, Process, LLM
from crewai_tools import DirectoryReadTool, FileReadTool, FileWriterTool
from crewai.tools import BaseTool

# --- 1. GLOBAL OVERRIDES (Stops OpenAI 401 Errors) ---
os.environ["OPENAI_API_KEY"] = "NA"
os.environ["OPENAI_API_BASE"] = "http://localhost:11434/v1"
os.environ["EMBEDDINGS_OLLAMA_MODEL_NAME"] = "nomic-embed-text"
os.environ["LITELLM_LOCAL_MODEL_TIMEOUT"] = "600"

# --- 2. TASK INPUT ---
# Pass the feature/task you want implemented as a command line argument.
# Example: python main.py "Add a gold counter display to the ShopTab"
if len(sys.argv) < 2:
    print("Usage: python main.py \"<task description>\"")
    print("Example: python main.py \"Add a stamina bar to the BattleTab\"")
    sys.exit(1)

USER_TASK = sys.argv[1]
PROJECT_PATH = r'C:\Projects\flutter\wanderers_trail'
LIB_PATH = rf'{PROJECT_PATH}\lib'


# --- 3. CUSTOM TOOLS ---
class GitControlTool(BaseTool):
    name: str = "git_control_tool"
    description: str = (
        "Manages Git operations. "
        "Supported commands: "
        "'create_branch' (requires branch_name), "
        "'commit_all' (requires message)."
    )

    def _run(self, command: str, branch_name: str = None, message: str = None) -> str:
        try:
            if command in ["create_branch", "checkout"]:
                if not branch_name:
                    return "Error: branch_name is required."
                result = subprocess.run(
                    ["git", "branch", "--list", branch_name],
                    capture_output=True, text=True, cwd=PROJECT_PATH
                )
                if branch_name in result.stdout:
                    subprocess.run(["git", "checkout", branch_name],
                                   capture_output=True, cwd=PROJECT_PATH)
                    return f"Switched to existing branch: '{branch_name}'."
                else:
                    subprocess.run(["git", "checkout", "-b", branch_name],
                                   capture_output=True, cwd=PROJECT_PATH)
                    return f"Created and switched to new branch: '{branch_name}'."

            elif command == "commit_all":
                if not message:
                    return "Error: A commit message is required."
                subprocess.run(["git", "add", "."], cwd=PROJECT_PATH)
                result = subprocess.run(
                    ["git", "commit", "-m", message],
                    capture_output=True, text=True, cwd=PROJECT_PATH
                )
                if "nothing to commit" in result.stdout:
                    return "Nothing to commit – working tree is clean."
                return f"Committed successfully:\n{result.stdout}"

            return f"Unknown command: '{command}'. Use 'create_branch' or 'commit_all'."

        except Exception as e:
            return f"Git Error: {str(e)}"


# --- 4. LOCAL LLM & TOOLS ---
local_llm = LLM(
    model="ollama/qwen2.5-coder:14b",
    base_url="http://localhost:11434",
    temperature=0.1,
    timeout=600,
)

dir_tool = DirectoryReadTool(directory=LIB_PATH)
file_read_tool = FileReadTool()
file_write_tool = FileWriterTool()
git_tool = GitControlTool()


# --- 5. AGENTS ---
code_planner = Agent(
    role="Flutter Code Planner",
    goal=(
        "Understand the existing codebase and produce a precise, step-by-step "
        "implementation plan for the given task."
    ),
    backstory=(
        "You are a senior Flutter/Dart architect. You first explore the project "
        "structure with the directory tool, then read ONLY the files relevant to "
        "the task. You output a numbered plan: which files to create or modify, "
        "exactly what to change, and how the new code should look."
    ),
    tools=[dir_tool, file_read_tool],
    llm=local_llm,
    max_iter=8,
    verbose=True,
)

game_designer = Agent(
    role="UX Game Design Advisor",
    goal=(
        "Review the existing game code and the Code Planner's plan, then propose "
        "creative, engaging UX improvements specific to this game's genre and mechanics."
    ),
    backstory=(
        "You are an experienced mobile game designer who has shipped RPGs, idle games, "
        "and roguelikes. You understand what makes games feel rewarding — juicy feedback, "
        "progression systems, visual clarity. You ALWAYS ground your suggestions in what "
        "already exists in the code (read 1-2 relevant files first), then output 3-5 "
        "concrete, implementable ideas. Each idea must include: (1) the feature name, "
        "(2) why it improves engagement, (3) a brief Flutter/Dart implementation hint."
    ),
    tools=[file_read_tool],
    llm=local_llm,
    max_iter=4,
    verbose=True,
)

flutter_dev = Agent(
    role="Senior Flutter Developer",
    goal="Implement the code changes described in the plan, one file at a time.",
    backstory=(
        "You are a pragmatic Dart developer. You receive a plan, read each target "
        "file with file_read_tool, apply improvements, then write the ENTIRE "
        "updated file content using file_writer_tool. "
        "RULES: (1) Never write partial snippets — always write the complete file. "
        "(2) Do not repeat a write action for the same file. "
        "(3) Once all files are written, output your Final Answer immediately."
    ),
    tools=[file_read_tool, file_write_tool],
    llm=local_llm,
    max_iter=5,
    verbose=True,
)

release_manager = Agent(
    role="Release Manager",
    goal="Commit all implemented changes to a feature git branch.",
    backstory=(
        "You are a meticulous release engineer. You create a feature branch if one "
        "does not exist, then commit all staged changes with a clear, professional "
        "commit message that describes what was implemented."
    ),
    tools=[git_tool],
    llm=local_llm,
    max_iter=3,
    verbose=True,
)


# --- 6. TASKS ---
task_plan = Task(
    description=(
        f"The Flutter project is located at: {LIB_PATH}\n\n"
        f"USER TASK: {USER_TASK}\n\n"
        "Your job:\n"
        "1. Use the directory tool to list files in the lib folder.\n"
        "2. Read the files that are relevant to this task.\n"
        "3. Output a numbered implementation plan with: the exact files to modify "
        "or create, and the precise code changes required (full class/widget names, "
        "property names, logic). Be specific enough that a developer can implement "
        "it without guessing."
    ),
    expected_output=(
        "A numbered implementation plan. Each item must include: "
        "(a) the full file path, (b) whether to CREATE or MODIFY it, "
        "(c) exactly what code to add or change."
    ),
    agent=code_planner,
)
task_design = Task(
    description=(
        f"The user wants to implement this in the game:\n  {USER_TASK}\n\n"
        "You have the Code Planner's technical plan in your context. "
        "Now add the game design perspective. Read 1-2 relevant source files "
        "(e.g. battle_tab.dart, pet_tab.dart) to understand the current UX, then "
        "propose 3-5 creative improvements that would make this feature more "
        "engaging, satisfying, or polished for the player. "
        "Think about: visual feedback, animations, progression hooks, sound cues, "
        "or small surprises that delight the player."
    ),
    expected_output=(
        "A list of 3-5 game design suggestions, each with: feature name, "
        "why it improves player engagement, and a concrete Flutter implementation hint."
    ),
    agent=game_designer,
    context=[task_plan],
)

task_implement = Task(
    description=(
        f"USER TASK: {USER_TASK}\n\n"
        "Follow the implementation plan from the Code Planner (in your context). "
        "For each file in the plan:\n"
        "1. Read the current file content with file_read_tool.\n"
        "2. Apply the planned changes.\n"
        "3. Write the FULL updated file using file_writer_tool.\n"
        "Do NOT write partial snippets. Do NOT re-write the same file twice. "
        "When all files are written, immediately output your Final Answer."
    ),
    expected_output=(
        "Confirmation that each planned file was written successfully, "
        "with a brief summary of what was changed in each file."
    ),
    agent=flutter_dev,
    context=[task_plan, task_design],
)

task_commit = Task(
    description=(
        "The developer has just implemented code changes for this task:\n"
        f"  {USER_TASK}\n\n"
        "Your job:\n"
        "1. Create or switch to the branch 'feature/ai-coding' using git_control_tool "
        "with command='create_branch' and branch_name='feature/ai-coding'.\n"
        "2. Commit all changes using git_control_tool with command='commit_all' and "
        "a helpful, concise commit message describing what was implemented.\n"
        "3. Report the result as your Final Answer."
    ),
    expected_output="Confirmation of git branch creation and commit with the commit message used.",
    agent=release_manager,
    context=[task_implement],
)


# --- 7. CREW ---
coding_crew = Crew(
    agents=[code_planner, game_designer, flutter_dev, release_manager],
    tasks=[task_plan, task_design, task_implement, task_commit],
    process=Process.sequential,
    memory=False,
    verbose=True,
)


# --- 8. RUN ---
if __name__ == "__main__":
    print(f"\n{'='*60}")
    print(f"  Wanderers Trail - AI Coding Agent")
    print(f"  Task: {USER_TASK}")
    print(f"{'='*60}\n")
    result = coding_crew.kickoff()
    print("\n\n" + "="*60)
    print("  WORKFLOW COMPLETE")
    print("="*60)
    print(result)