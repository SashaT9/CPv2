from typing import List
from fastapi.security import OAuth2PasswordBearer
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.staticfiles import StaticFiles
from . import models, schemas, crud_user, crud_contest
from .database import engine, get_db
from .crud_user import *
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

@app.get("/user-achievements/", response_model=schemas.UserAchievement)
def read_user_achievements(db: Session = Depends(get_db), token: schemas.TokenData = Depends(get_current_user)):
    user_id = token.user_id  # Assuming your token holds user_id
    achievements = crud_user.get_user_achievements(db, user_id)
    if achievements is None:
        raise HTTPException(status_code=404, detail="Achievements not found")
    return achievements
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

