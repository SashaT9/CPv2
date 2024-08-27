from enum import verify

from fastapi import HTTPException
from sqlalchemy.orm import Session
from . import models, schemas
from .auth import get_password_hash, verify_password, create_access_token
from .models import UserSettingsLog, User
from .schemas import UserCreate, UserLogin


def signup_user(db:Session, user: UserCreate):
        db_user = db.query(User).filter(User.username == user.username).first()
        if (db_user):
            raise HTTPException(status_code=400, detail='Username already taken')

        db_user_by_email = db.query(User).filter(User.email == user.email).first()
        if (db_user_by_email):
            raise HTTPException(status_code=400, detail='Email already registered')

        hashed_password = get_password_hash(user.password)
        new_user = User(
            username = user.username,
            password = hashed_password,
            email = user.email,
            role = user.role
        )

        db.add(new_user)
        db.commit()
        db.refresh(new_user)

        return new_user


def signin_user(db:Session, user: UserLogin):
    db_user = db.query(User).filter(User.username == user.username).first()
    if not db_user or not verify_password(user.password, db_user.password):
        raise HTTPException(status_code=400, detail='Incorrect username or password')

    access_token = create_access_token(data={"sub": db_user.username, "is_admin": db_user.is_admin})
    return {"access_token": access_token, "token_type": "bearer"}

def get_users(db: Session):
    return db.query(models.User).all()

def delete_user(db: Session, user_id: int):
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if user:
        db.delete(user)
        db.commit()
        return True
    return False

def update_user(db: Session, user_id: int, user_update: schemas.UserUpdate):
    db_user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not db_user:
        return None

    for key, value in user_update.dict(exclude_unset=True).items():
        setattr(db_user, key, value)

    db.commit()
    db.refresh(db_user)
    return db_user

def add_user_achievement(db: Session, achievement: schemas.UserAchievementCreate):
    db_achievement = models.UserAchievement(**achievement.dict())
    db.add(db_achievement)
    db.commit()
    db.refresh(db_achievement)
    return db_achievement

def get_user_achievements(db: Session, user_id: int):
    return db.query(models.UserAchievement).filter(models.UserAchievement.user_id == user_id).all()

def update_user_achievement(db: Session, user_id: int, achievement: schemas.UserAchievementUpdate):
    db_achievement = db.query(models.UserAchievement).filter(models.UserAchievement.user_id == user_id).first()
    if db_achievement:
        for key, value in achievement.dict(exclude_unset=True).items():
            setattr(db_achievement, key, value)
        db.commit()
        db.refresh(db_achievement)
        return db_achievement
    return None


def get_user_logs(db: Session, user_id: int):
    return db.query(UserSettingsLog).filter(UserSettingsLog.user_id == user_id).all()


def authenticate_user(db: Session, username: str, password: str):
    user = db.query(User).filter(User.username == username).first()
    if not user or password != user.password:
        return None
    return user
