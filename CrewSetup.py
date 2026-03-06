from crewai import Agent, Task, Crew
from langchain_community.llms import Ollama

# Initialize the local brain (Qwen 2.5 Coder is great for this)
llm = Ollama(model="qwen2.5-coder:14b")

# Define the specialized OpenSop Agents
ux_agent = Agent(
    role='Lead Flutter UI/UX Designer',
    goal='Design the "SOP Execution" screen for OpenSop mobile.',
    backstory='Expert in B2B mobile flows for industrial environments.',
    llm=llm
)

dev_agent = Agent(
    role='Full-Stack Systems Engineer',
    goal='Create the SQLAlchemy model and API endpoint for SOP submission.',
    backstory='Expert in Python, SQLAlchemy, and C# integrations.',
    llm=llm
)

# Example Task
task_design = Task(
    description="Draft a JSON schema for a multi-step SOP that includes image uploads and digital signatures.",
    agent=ux_agent,
    expected_output="A structured JSON format for OpenSop's dynamic forms."
)

# Start the crew
open_sop_crew = Crew(agents=[ux_agent, dev_agent], tasks=[task_design])
open_sop_crew.kickoff()