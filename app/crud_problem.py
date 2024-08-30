from sqlalchemy.orm import Session
from app.models import Problem
from .schemas import ProblemCreate

def create_problem(db: Session, problem_data: ProblemCreate):
    new_problem = Problem(
        statement=problem_data.statement,
        answer=problem_data.answer,
        output_only=problem_data.output_only,
        topic=1
    )
    db.add(new_problem)
    db.commit()
    db.refresh(new_problem)
    return new_problem

def get_problem(db: Session, problem_id: int):
    return db.query(Problem).filter(Problem.problem_id == problem_id).first()

