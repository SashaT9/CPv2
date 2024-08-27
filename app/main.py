from typing import List
from fastapi.security import OAuth2PasswordBearer
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.staticfiles import StaticFiles
from . import models, schemas, crud_user, crud_contest
from .database import engine, get_db
from .crud_user import *

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

app.mount("/static", StaticFiles(directory="./frontend", html=True), name="frontend")

@app.post("/signup/")
def signup(user: UserCreate, db: Session = Depends(get_db)):
    return signup_user(db=db, user=user)

@app.post("/signin/")
def signin(user: UserLogin, db: Session = Depends(get_db)):
    return signin_user(db=db, user=user)

@app.get("/users/", response_model=list[schemas.User])
def read_users(db: Session = Depends(get_db)):
    users = crud_user.get_users(db)
    return users

@app.delete("/users/{user_id}/", response_model=schemas.Message)
def delete_user(user_delete: schemas.UserDelete, db: Session = Depends(get_db)):
    user = crud_user.authenticate_user(db, user_delete.username, user_delete.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password"
        )
    result = crud_user.delete_user(db, user.user_id)
    if result:
        return {"message": "User deleted successfully"}
    else:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

@app.put("/users/{user_id}/", response_model=schemas.User)
def update_user(user_id: int, user_update: schemas.UserUpdate, db: Session = Depends(get_db)):
    updated_user = crud_user.update_user(db, user_id, user_update)
    if not updated_user:
        raise HTTPException(status_code=404, detail="User not found")
    return updated_user

@app.post("/users/{user_id}/achievements/", response_model=schemas.UserAchievement)
def add_achievement(user_id: int, achievement: schemas.UserAchievementCreate, db: Session = Depends(get_db)):
    # Check if the user exists
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    # Create and add the achievement
    achievement.user_id = user_id
    return crud_user.add_user_achievement(db, achievement)

@app.get("/users/{user_id}/achievements/", response_model=list[schemas.UserAchievement])
def get_achievements(user_id: int, db: Session = Depends(get_db)):
    return crud_user.get_user_achievements(db, user_id)

@app.put("/users/{user_id}/achievements/", response_model=schemas.UserAchievement)
def update_achievement(user_id: int, achievement: schemas.UserAchievementUpdate, db: Session = Depends(get_db)):
    updated_achievement = crud_user.update_user_achievement(db, user_id, achievement)
    if not updated_achievement:
        raise HTTPException(status_code=404, detail="Achievement not found")
    return updated_achievement

@app.get("/users/{user_id}/logs", response_model=List[schemas.UserLog])
def show_user_logs(user_id: int, db: Session = Depends(get_db)):
    logs = crud_user.get_user_logs(db, user_id)
    if not logs:
        raise HTTPException(status_code=404, detail="Logs not found for user")
    return logs


# this is for Frontend for logining
@app.post("/login/")
def login(user: schemas.UserDelete, db: Session = Depends(get_db)):
    db_user = crud_user.authenticate_user(db, user.username, user.password)
    if not db_user:
        raise HTTPException(status_code=400, detail="Incorrect username or password")
    return {"username": db_user.username, "role": db_user.role}

# Contest operations
@app.post("/admin/contests/", response_model=schemas.Contest)
def create_contest(contest: schemas.ContestCreate, db: Session = Depends(get_db)):
    return crud_contest.create_contest(db=db, contest=contest)

@app.get("/contests/", response_model=List[schemas.Contest])
def read_contests(db: Session = Depends(get_db)):
    return crud_contest.get_contests(db)

@app.get("/contests/{contest_id}/", response_model=schemas.Contest)
def read_contest(contest_id: int, db: Session = Depends(get_db)):
    contest = crud_contest.get_contest_by_id(db, contest_id)
    if contest is None:
        raise HTTPException(status_code=404, detail="Contest not found")
    return contest

@app.put("/admin/contests/{contest_id}/", response_model=schemas.Contest)
def update_contest(contest_id: int, contest_update: schemas.ContestUpdate, db: Session = Depends(get_db)):
    updated_contest = crud_contest.update_contest(db, contest_id, contest_update)
    if not updated_contest:
        raise HTTPException(status_code=404, detail="Contest not found")
    return updated_contest

@app.delete("/admin/contests/{contest_id}/", response_model=schemas.Message)
def delete_contest(contest_id: int, db: Session = Depends(get_db)):
    result = crud_contest.delete_contest(db, contest_id)
    if result:
        return {"message": "Contest deleted successfully"}
    else:
        raise HTTPException(status_code=404, detail="Contest not found")

