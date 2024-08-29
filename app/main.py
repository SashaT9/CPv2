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


@app.put("/user-info/", response_model=schemas.User)
def update_user_info(
    user_update: schemas.UserUpdate,
    db: Session = Depends(get_db),
    token: str = Depends(get_current_user)
):
    user_id = token.user_id  # Extract user_id from token
    updated_user = update_user(db, user_id, user_update)
    return updated_user


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
