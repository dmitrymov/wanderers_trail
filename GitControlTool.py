import subprocess
from crewai.tools import BaseTool

class GitControlTool(BaseTool):
    name: str = "git_control_tool"
    description: str = "Инструмент для работы с Git: создание веток, add и commit."

    def _run(self, command: str, branch_name: str = None, message: str = None) -> str:
        try:
            if command == "create_branch":
                subprocess.run(["git", "checkout", "-b", branch_name], check=True, cwd=project_path)
                return f"Ветка {branch_name} создана."
            
            elif command == "commit_all":
                subprocess.run(["git", "add", "."], check=True, cwd=project_path)
                subprocess.run(["git", "commit", "-m", message], check=True, cwd=project_path)
                return f"Изменения закоммичены с сообщением: {message}"
            
            return "Команда не распознана."
        except Exception as e:
            return f"Ошибка Git: {str(e)}"

git_tool = GitControlTool()