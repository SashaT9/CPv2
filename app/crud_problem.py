from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.models import Problem, Solution, Submission
from .schemas import ProblemCreate

def create_problem(db: Session, problem_data: ProblemCreate):
    new_problem = Problem(
        statement=problem_data.statement,
        answer=problem_data.answer,
        output_only=problem_data.output_only
    )
    db.add(new_problem)
    db.commit()
    db.refresh(new_problem)
    return new_problem

def get_problem(db: Session, problem_id: int):
    return db.query(Problem).filter(Problem.problem_id == problem_id).first()

def create_solution(db: Session, answer: str) -> Solution:
    new_solution = Solution(answer=answer)
    db.add(new_solution)
    db.commit()
    db.refresh(new_solution)
    return new_solution

def create_submission(db: Session, user_id: int, problem_id: int, solution_id: int, status: str):
    new_submission = Submission(
        user_id=user_id,
        problem_id=problem_id,
        solution_id=solution_id,
        status=status
    )
    db.add(new_submission)
    db.commit()
    db.refresh(new_submission)
    return new_submission

def check_solution(db: Session, problem_id: int, user_answer: str) -> str:
    # Retrieve the correct answer for the problem
    problem = db.query(Problem).filter(Problem.problem_id == problem_id).first()
    if not problem:
        raise HTTPException(status_code=404, detail="Problem not found")

    if problem.answer == user_answer:
        return "accepted"
    else:
        return "wrong answer"

