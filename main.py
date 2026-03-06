import os
import subprocess
from crewai import Agent, Task, Crew, Process, LLM
from crewai_tools import DirectoryReadTool, FileReadTool, FileWriterTool
from crewai.tools import BaseTool

# --- 1. GLOBAL OVERRIDES (Stops OpenAI 401 Errors) ---
os.environ["OPENAI_API_KEY"] = "NA"
os.environ["OPENAI_API_BASE"] = "http://localhost:11434/v1"
os.environ["EMBEDDINGS_OLLAMA_MODEL_NAME"] = "nomic-embed-text"
os.environ["LITELLM_LOCAL_MODEL_TIMEOUT"] = "600"


# --- 2. PATH CONFIGURATION ---
PROJECT_PATH = r'C:\Projects\flutter\wanderers_trail'

# --- 3. CUSTOM TOOLS ---
class GitControlTool(BaseTool):
    name: str = "git_control_tool"
    description: str = "Manage Git operations: branch creation, switching (checkout), adding files, and committing changes."
    cache_function: bool = False

    def _run(self, command: str, branch_name: str = None, message: str = None) -> str:
        """
        Executes git commands in the specified PROJECT_PATH.
        Supported commands: 'create_branch', 'checkout', 'commit_all'
        """
        import subprocess
        
        try:
            # 1. CREATE OR SWITCH BRANCH (Handles 'create_branch' and 'checkout' aliases)
            if command in ["create_branch", "checkout"]:
                if not branch_name:
                    return "Error: branch_name is required for this command."

                # Check if the branch already exists locally
                result = subprocess.run(
                    ["git", "branch", "--list", branch_name],
                    capture_output=True, text=True, cwd=PROJECT_PATH, check=True
                )
                
                if branch_name in result.stdout:
                    # Branch exists, just switch to it
                    subprocess.run(["git", "checkout", branch_name], 
                                 capture_output=True, text=True, cwd=PROJECT_PATH, check=True)
                    return f"Branch '{branch_name}' already exists. Switched to it successfully."
                else:
                    # Branch doesn't exist, create and switch
                    subprocess.run(["git", "checkout", "-b", branch_name], 
                                 capture_output=True, text=True, cwd=PROJECT_PATH, check=True)
                    return f"Created and switched to new branch: '{branch_name}'."

            # 2. COMMIT ALL CHANGES
            elif command == "commit_all":
                if not message:
                    return "Error: A commit message is required."
                
                # Add all changes
                subprocess.run(["git", "add", "."], cwd=PROJECT_PATH, check=True)
                
                # Commit
                commit_result = subprocess.run(
                    ["git", "commit", "-m", message],
                    capture_output=True, text=True, cwd=PROJECT_PATH
                )
                
                if "nothing to commit" in commit_result.stdout:
                    return "Git Update: Nothing to commit"
                else:
                    return f"Git Commit Success: {commit_result.stdout}"

            return "Unknown command provided to GitControlTool."

        except subprocess.CalledProcessError as e:
            return f"Git Process Error: {e.stderr if e.stderr else str(e)}"
        except Exception as e:
            return f"Unexpected Error in GitControlTool: {str(e)}"

# --- 4. INITIALIZE LOCAL MODELS & TOOLS ---
# Using the 'ollama/' prefix tells CrewAI to route through the local server
local_llm = LLM(
    model="ollama/qwen2.5-coder:14b",
    base_url="http://localhost:11434",
    temperature=0.1,
    timeout=600
)

dir_tool = DirectoryReadTool(directory=PROJECT_PATH)
file_read_tool = FileReadTool()
file_write_tool = FileWriterTool() 
git_tool = GitControlTool()

# --- 5. AGENT DEFINITIONS ---
release_manager = Agent(
    role='Release Manager',
    goal='Manage project versioning and clean commits.',
    backstory='Meticulous release engineer ensuring repo organization.',
    tools=[git_tool],
    llm=local_llm,
    max_iter=3,
    verbose=True
)

ui_analyst = Agent(
    role='Flutter UX/UI Analyst',
    goal='Identify one specific UI improvement in the lib folder.',
    backstory='Expert in Flutter Material 3. You find padding and alignment issues.',
    tools=[dir_tool, file_read_tool],
    llm=local_llm,
    verbose=True
)

flutter_developer = Agent(
    role='Senior Flutter Developer',
    goal='Apply UI improvements to Dart files.',
    backstory='You are a pragmatist. If you write a file once, you move on.',
    tools=[file_read_tool, file_write_tool],
    llm=local_llm,
    max_iter=2,
    verbose=True
)

file_write_tool.cache_function = False

# --- 6. TASK DEFINITIONS ---
task_git_init = Task(
    description="Check if the git branch 'feature/ai-ux-updates' is active. If not, switch/create it. "
                "Once the tool confirms the branch is active, immediately finish and provide the branch name as your Final Answer.",
    expected_output="The name of the active branch.",
    agent=release_manager
)

task_analyze_ui = Task(
    description=f"Scan the {PROJECT_PATH}/lib directory. Identify ONE specific file and UI improvement.",
    expected_output="The full file path and a list of specific UI changes.",
    agent=ui_analyst
)

# task_apply_changes = Task(
#     description=(
#         "1. Take the UI Analyst's suggestions.\n"
#         "2. Rewrite the Dart code for the chosen file.\n"
#         "3. CRITICAL: You MUST call the 'file_writer_tool' with the FULL content. "
#         "If you do not call the tool, the task is a failure."
#     ),
#     expected_output="Confirmation from the file_writer_tool that the file was saved.",
#     agent=flutter_developer,
#     context=[task_analyze_ui]
# )

task_apply_changes = Task(
    description=(
        "Rewrite the chosen Dart file. If the file is already optimized, "
        "make a small comment change to verify the write, save it using 'file_writer_tool', "
        "and immediately provide your Final Answer. Do not repeat the action more than once."
    ),
    expected_output="Confirmation that the file was saved or no changes were necessary.",
    agent=flutter_developer
)

task_git_commit = Task(
    description="Commit all changes to the repository with a descriptive message.",
    expected_output="Git commit confirmation.",
    agent=release_manager,
    context=[task_apply_changes]
)

# --- 7. CREW ASSEMBLY ---
# --- 7. CREW ASSEMBLY ---
wanderers_crew = Crew(
    agents=[release_manager, ui_analyst, flutter_developer],
    tasks=[task_git_init, task_analyze_ui, task_apply_changes, task_git_commit],
    process=Process.sequential,
    memory=False,
    verbose=True,
    manager_llm=local_llm,
    embedder={
        "provider": "ollama",
        "config": {
            "model": "nomic-embed-text",
            "model_name": "nomic-embed-text",
            "base_url": "http://localhost:11434"
        }
    }
)

# --- 8. EXECUTION ---
if __name__ == "__main__":
    print(f"### Starting Local Agent Crew for: Wanderers Trail")
    result = wanderers_crew.kickoff()
    print("\n\n########################")
    print("## WORKFLOW COMPLETED ##")
    print("########################\n")
    print(result)