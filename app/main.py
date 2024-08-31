from typing import List
from fastapi.security import OAuth2PasswordBearer
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.staticfiles import StaticFiles
from sqlalchemy import desc
from sqlalchemy.orm import joinedload

from . import models, schemas, crud_user, crud_announce, crud_problem
from .database import engine, get_db
from .crud_user import *
from .crud_problem import create_problem
from .auth import get_current_user

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

app.mount("/index", StaticFiles(directory="./frontend", html=True), name="frontend")

@app.post("/signup/")
def signup(user: UserCreate, db: Session = Depends(get_db)):
    return signup_user(db=db, user=user)

@app.post("/signin/")
def signin(user: UserLogin, db: Session = Depends(get_db)):
    return signin_user(db=db, user=user)

@app.get("/user-info/")
async def get_user_info(current_user: models.User = Depends(get_current_user)):
    return current_user

@app.put("/user-info/", response_model=schemas.User)
def update_user_info(
    user_update: schemas.UserUpdate,
    db: Session = Depends(get_db),
    token: str = Depends(get_current_user)
):
    user_id = token.user_id  # Extract user_id from token
    updated_user = update_user(db, user_id, user_update)
    return updated_user

@app.delete("/user-info/", status_code=status.HTTP_204_NO_CONTENT)
def delete_user_info(
    db: Session = Depends(get_db),
    token: schemas.TokenData = Depends(get_current_user)
):
    user_id = token.user_id  # Extract user_id from token
    delete_user(db, user_id)

    return {"message": "User deleted successfully"}



@app.get("/user-achievements/", response_model=schemas.UserAchievement)
def read_user_achievements(db: Session = Depends(get_db), token: schemas.TokenData = Depends(get_current_user)):
    user_id = token.user_id  # Assuming your token holds user_id
    achievements = crud_user.get_user_achievements(db, user_id)
    if achievements is None:
        raise HTTPException(status_code=404, detail="Achievements not found")
    return achievements

@app.post("/problems/", response_model=schemas.Problem)
def create_problem(
        problem: schemas.ProblemCreate,
        db: Session = Depends(get_db),
        token: schemas.TokenData = Depends(get_current_user)
):
    user = db.query(User).filter(User.user_id == token.user_id).first()
    if not user or not user.is_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")
    return crud_problem.create_problem(db, problem)

@app.get("/problems/{problem_id}", response_model=schemas.Problem)
def get_problem(
    problem_id: int,
    db: Session = Depends(get_db),
    token: schemas.TokenData = Depends(get_current_user)
):
    problem = crud_problem.get_problem(db, problem_id)
    if not problem:
        raise HTTPException(status_code=404, detail="Problem not found")
    return problem

@app.get("/problems/", response_model=List[schemas.Problem])
def read_problems(skip: int = 0, limit: int = 10, db: Session = Depends(get_db)):
    problems = db.query(models.Problem).offset(skip).limit(limit).all()
    return problems

@app.post("/announcements/", response_model=schemas.Announcement)
def create_announcement(
    announcement: schemas.AnnouncementCreate,
    db: Session = Depends(get_db),
    token: schemas.TokenData = Depends(get_current_user)
):
    return crud_announce.create_announcement(db, announcement, token.user_id)

@app.get("/announcements/{announcement_id}", response_model=schemas.Announcement)
def get_announcement(
    announcement_id: int,
    db: Session = Depends(get_db)
):
    return crud_announce.get_announcement(db, announcement_id)

@app.put("/announcements/{announcement_id}", response_model=schemas.Announcement)
def update_announcement(
    announcement_id: int,
    updated_announcement: schemas.AnnouncementCreate,
    db: Session = Depends(get_db),
    token: schemas.TokenData = Depends(get_current_user)
):
    return crud_announce.update_announcement(db, announcement_id, updated_announcement, token.user_id)

@app.delete("/announcements/{announcement_id}", response_model=schemas.Announcement)
def delete_announcement(
    announcement_id: int,
    db: Session = Depends(get_db),
    token: schemas.TokenData = Depends(get_current_user)
):
    return crud_announce.delete_announcement(db, announcement_id, token.user_id)

@app.get("/announcements/", response_model=list[schemas.Announcement])
def read_announcements(db: Session = Depends(get_db)):
    try:
        # Fetch all announcements and sort them by date_posted in descending order
        announcements = db.query(models.Announcement).order_by(desc(models.Announcement.date_posted)).all()
        return announcements
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching announcements: {str(e)}")


@app.post("/problems/{problem_id}/submit/", response_model=schemas.SubmissionResponse)
def submit_solution(
        problem_id: int,  # Added path parameter here
        submission_data: schemas.SubmissionCreate,
        db: Session = Depends(get_db),
        token: schemas.TokenData = Depends(get_current_user)
):
    user = db.query(models.User).filter(models.User.user_id == token.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    problem = db.query(models.Problem).filter(models.Problem.problem_id == problem_id).first()  # Use problem_id from path
    if not problem:
        raise HTTPException(status_code=404, detail="Problem not found")

    new_solution = crud_problem.create_solution(db, submission_data.answer)

    status = crud_problem.check_solution(db, problem.problem_id, submission_data.answer)

    new_submission = crud_problem.create_submission(
        db,
        user.user_id,
        problem.problem_id,
        new_solution.solution_id,
        status
    )
    return schemas.SubmissionResponse(
        answer=new_solution.answer,
        problem_id=problem.problem_id,
        status=status)

@app.get("/users/{user_id}/submissions", response_model=List[schemas.SubmissionResponse])
def get_user_submissions(user_id: int, problemId: int, db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    submissions = (
        db.query(models.Submission)
        .filter(models.Submission.user_id == user_id, models.Submission.problem_id == problemId)
        .all()
    )

    if not submissions:
        raise HTTPException(status_code=404, detail="No submissions found for this problem")

    submissions.reverse()

    solution_ids = [s.solution_id for s in submissions]
    solutions = {sol.solution_id: sol for sol in db.query(models.Solution).filter(models.Solution.solution_id.in_(solution_ids)).all()}

    return [
        schemas.SubmissionResponse(
            answer=solutions[submission.solution_id].answer,
            problem_id=submission.problem_id,
            status=submission.status
        )
        for submission in submissions
    ]

@app.delete("/problems/{problemId}/delete")
def delete_problem(
        problemId: int,
        db: Session = Depends(get_db),
        token: schemas.TokenData = Depends(get_current_user)
):
    user = db.query(models.User).filter(models.User.user_id == token.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    problem = db.query(models.Problem).filter(models.Problem.problem_id == problemId).first()
    if not problem:
        raise HTTPException(status_code=404, detail="Problem not found")

    db.delete(problem)
    db.commit()
    return {"detail": "Problem deleted successfully"}

@app.put("/problems/{problemId}/update")
def update_problem(
        problemId: int,
        update_data: schemas.ProblemUpdate,
        db: Session = Depends(get_db),
        token: schemas.TokenData = Depends(get_current_user)
):
    user = db.query(models.User).filter(models.User.user_id == token.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    problem = db.query(models.Problem).filter(models.Problem.problem_id == problemId).first()
    if not problem:
        raise HTTPException(status_code=404, detail="Problem not found")

    problem.statement = update_data.statement
    problem.answer = update_data.answer
    db.commit()

    return {"detail": "Problem updated successfully"}

@app.get("/users/", response_model=list[schemas.User])
def read_users(db: Session = Depends(get_db)):
    users = crud_user.get_users(db)
    return users

@app.get("/contests/", response_model=List[schemas.Contest])
def get_contests(db: Session = Depends(get_db)):
    contests = db.query(models.Contest).all()
    return contests

@app.post("/contests/", response_model=schemas.ContestCreate)
def create_contest(
    contest: schemas.ContestCreate,
    db: Session = Depends(get_db),
    token: schemas.TokenData = Depends(get_current_user)
):
    user = db.query(User).filter(User.user_id == token.user_id).first()
    if not user or not user.is_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    return crud_problem.create_contest(db, contest)

@app.post("/register-contest/{contest_id}", response_model=schemas.ContestParticipant)
def register_for_contest(
    contest_id: int,
    db: Session = Depends(get_db),
    token: schemas.TokenData = Depends(get_current_user)
):
    user = db.query(models.User).filter(User.user_id == token.user_id).first()
    if not user:
        raise HTTPException(status_code=403, detail="User not found")

    # Check if the contest exists
    contest = db.query(models.Contest).filter(models.Contest.contest_id == contest_id).first()
    if not contest:
        raise HTTPException(status_code=404, detail="Contest not found")

    # Check if the user is already registered
    existing_participant = db.query(models.ContestParticipant).filter(
        models.ContestParticipant.contest_id == contest_id,
        models.ContestParticipant.user_id == token.user_id
    ).first()

    if existing_participant:
        raise HTTPException(status_code=400, detail="User already registered for this contest")

    # Create a new participant entry
    new_participant = models.ContestParticipant(
        contest_id=contest_id,
        user_id=token.user_id,
        score=0,
        rank=1
    )
    db.add(new_participant)
    db.commit()
    db.refresh(new_participant)

    return new_participant

@app.get("/check-registration/{contest_id}", response_model=bool)
def check_registration(
    contest_id: int,
    db: Session = Depends(get_db),
    token: schemas.TokenData = Depends(get_current_user)
):
    user = db.query(User).filter(User.user_id == token.user_id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User not found")

    is_registered = db.query(models.ContestParticipant).filter(
        models.ContestParticipant.contest_id == contest_id,
        models.ContestParticipant.user_id == token.user_id
    ).first() is not None

    return is_registered