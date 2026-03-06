import os
os.environ["OPENAI_API_KEY"] = "NA"
os.environ["EMBEDDINGS_OLLAMA_MODEL_NAME"] = "nomic-embed-text"
import subprocess
from crewai import Agent, Task, Crew, Process
from crewai_tools import DirectoryReadTool, FileReadTool, FileWriterTool
from langchain_ollama import ChatOllama
from crewai.tools import BaseTool

# --- PATH CONFIGURATION ---
PROJECT_PATH = r'C:\Projects\flutter\wanderers_trail'

class FlutterCheckTool(BaseTool):
    name: str = "flutter_check_tool"
    description: str = "Runs flutter analyze to catch syntax errors or dart format to fix styling."

    def _run(self, command: str) -> str:
        try:
            if command == "analyze":
                result = subprocess.run(
                    ["flutter", "analyze"], 
                    capture_output=True, text=True, cwd=PROJECT_PATH
                )
                return result.stdout if result.returncode == 0 else f"Errors found:\n{result.stdout}"
            
            elif command == "format":
                subprocess.run(["dart", "format", "."], check=True, cwd=PROJECT_PATH)
                return "Code formatted successfully."
                
            return "Unknown command."
        except Exception as e:
            return f"Tool Error: {str(e)}"

# Initialize it
flutter_check_tool = FlutterCheckTool()

# --- CUSTOM GIT TOOL ---
class GitControlTool(BaseTool):
    name: str = "git_control_tool"
    description: str = "Tool to manage Git operations: branch creation, add, and commit."

    def _run(self, command: str, branch_name: str = None, message: str = None) -> str:
        try:
            if command == "create_branch":
                subprocess.run(["git", "checkout", "-b", branch_name], check=True, cwd=PROJECT_PATH)
                return f"Branch {branch_name} created and checked out."
            
            elif command == "commit_all":
                subprocess.run(["git", "add", "."], check=True, cwd=PROJECT_PATH)
                subprocess.run(["git", "commit", "-m", message], check=True, cwd=PROJECT_PATH)
                return f"Changes committed successfully with message: {message}"
            
            return "Command not recognized."
        except Exception as e:
            return f"Git Error: {str(e)}"

import os
from crewai import LLM

# --- INITIALIZE TOOLS & MODEL ---
local_llm = LLM(
    model="ollama/qwen2.5-coder:14b-instruct",
    base_url="http://localhost:11434"
)

dir_tool = DirectoryReadTool(directory=PROJECT_PATH)
file_read_tool = FileReadTool()
file_write_tool = FileWriterTool()
git_tool = GitControlTool()

# --- MANAGER DEFINITION ---
project_manager = Agent(
    role='Technical Project Manager',
    goal='Optimize the OpenSop Flutter codebase by identifying and fixing UI/UX debt.',
    backstory='You are a veteran software architect overseeing the dev lifecycle.',
    allow_delegation=True,
    llm=local_llm,
    verbose=True
)

# --- AGENT DEFINITIONS ---
release_manager = Agent(
    role='Release Manager',
    goal='Manage project versioning, branches, and clean commits.',
    backstory='You are a meticulous release engineer. You ensure the repository stays organized and every change is documented.',
    tools=[git_tool],
    llm=local_llm,
    verbose=True
)

ui_analyst = Agent(
    role='Flutter UX/UI Analyst',
    goal='Analyze Dart code to identify UI inconsistencies and UX improvement opportunities.',
    backstory='Expert in Flutter Material 3 design systems. You have an eye for padding, typography, and widget composition.',
    tools=[dir_tool, file_read_tool],
    llm=local_llm,
    verbose=True
)

flutter_developer = Agent(
    role='Senior Flutter Developer',
    goal='Implement UI/UX improvements by modifying Dart files while maintaining clean code.',
    backstory='A Dart wizard who writes performant, readable code and follows Flutter best practices.',
    tools=[file_read_tool, file_write_tool],
    llm=local_llm,
    verbose=True
)

qa_engineer = Agent(
    role='QA Automation Specialist',
    goal='Verify the integrity of modified code using official Flutter tools.',
    backstory='You are a stickler for the rules. You use "flutter analyze" to ensure no linting or syntax errors exist.',
    tools=[file_read_tool, flutter_check_tool], # Added the tool here
    llm=local_llm,
    verbose=True
)

# --- TASK DEFINITIONS ---
task_git_init = Task(
    description="Create a new git branch named 'feature/ai-ux-updates' to isolate changes.",
    expected_output="Branch creation confirmation.",
    agent=release_manager
)

task_analyze_ui = Task(
    description=(
        f"Scan the {PROJECT_PATH}/lib directory. Identify a specific UI screen "
        "that could be improved. You MUST output the full file path and the suggested changes."
    ),
    expected_output="The full path of the file to modify and a detailed list of UI improvements.",
    agent=ui_analyst
)

task_apply_changes = Task(
    description=(
        "Based on the UI Analyst's report, modify the chosen Dart file. "
        "When using FileWriterTool, you MUST provide the complete file content. Never output snippets or placeholders like, use FileWriterTool to overwrite the file with the improved code."
    ),
    expected_output="The updated Dart source code with applied improvements.",
    agent=flutter_developer,
    context=[task_analyze_ui]
)

task_verify_code = Task(
    description=(
        "1. Read the modified Dart file.\n"
        "2. Run 'flutter_check_tool' with the 'analyze' command.\n"
        "3. If errors exist, list them. If clean, run 'format' to finalize."
    ),
    expected_output="A report confirming 'flutter analyze' passed with no issues.",
    agent=qa_engineer,
    context=[task_apply_changes]
)

task_git_commit = Task(
    description="Commit all changes to the repository with a professional, descriptive commit message in English.",
    expected_output="Git commit confirmation message.",
    agent=release_manager,
    context=[task_apply_changes, task_verify_code]
)

# --- DYNAMIC TASK DEFINITIONS ---
# Note: We removed the 'agent=' parameter; the Manager will assign these.

task_analyze_project = Task(
    description="Scan the /lib directory and find ONE file that needs UI improvement.",
    expected_output="The file path and a list of specific UX changes needed."
)

task_execute_improvement = Task(
    description="Modify the identified file to implement the improvements.",
    expected_output="The fully updated Dart code applied to the file."
)

task_qa_and_format = Task(
    description="Run 'analyze' and 'format' on the modified code to ensure it's production-ready.",
    expected_output="A clean report with no syntax errors."
)

## --- THE HIERARCHICAL CREW ---
#wanderers_crew = Crew(
#    agents=[ui_analyst, flutter_developer, qa_engineer], # Workers only
#    tasks=[task_analyze_project, task_execute_improvement, task_qa_and_format],
#    process=Process.hierarchical,
#    manager_agent=project_manager, # The "Boss"
#    verbose=True
#)

from crewai import Crew, Process

# --- THE SMART CREW ---
wanderers_crew = Crew(
    agents=[ui_analyst, flutter_developer, qa_engineer],
    tasks=[task_analyze_project, task_execute_improvement, task_qa_and_format],
    process=Process.hierarchical,
    manager_agent=project_manager,
    manager_llm=local_llm,
    memory=True,  
    verbose=True,
    embedder={
        "provider": "ollama",
        "config": {
            "model": "nomic-embed-text",
            "base_url": "http://localhost:11434" # Ensure this is explicitly here
        }
    }
)

# --- EXECUTION ---
if __name__ == "__main__":
    print(f"### Starting Multi-Agent Workflow for: Wanderers Trail")
    result = wanderers_crew.kickoff()
    print("\n\n########################")
    print("## WORKFLOW COMPLETED ##")
    print("########################\n")
    print(result)