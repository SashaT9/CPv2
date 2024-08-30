from typing import List
from fastapi.security import OAuth2PasswordBearer
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.staticfiles import StaticFiles
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
    return create_problem(db, problem)

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

@app.get("/users/", response_model=list[schemas.User])
def read_users(db: Session = Depends(get_db)):
    users = crud_user.get_users(db)
    return users
