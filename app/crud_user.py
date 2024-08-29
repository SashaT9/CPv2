from enum import verify
from sqlalchemy.exc import IntegrityError
from fastapi import HTTPException, status
from sqlalchemy.orm import Session
from . import models, schemas
from .auth import get_password_hash, verify_password, create_access_token
from .models import UserSettingsLog, User
from .schemas import UserCreate, UserLogin, UserUpdate
from .config import oauth2_scheme


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
            email = user.email
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

def get_user_achievements(db: Session, user_id: int) -> schemas.UserAchievement:
    achievements = db.query(models.UserAchievement).filter(models.UserAchievement.user_id == user_id).first()
    return achievements

def update_user(db: Session, user_id: int, user_update: schemas.UserUpdate):
    try:
        user = db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        if user_update.username:
            user.username = user_update.username
        if user_update.email:
            user.email = user_update.email
        if user_update.password:
            user.password = get_password_hash(user_update.password)

        db.add(user)
        db.commit()
        db.refresh(user)

        return user
    except IntegrityError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail="Integrity error: possibly a duplicate entry")
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail="An error occurred")

def delete_user(db: Session, user_id: int):
    user = db.query(User).filter(User.user_id == user_id).first()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )

    db.delete(user)
    db.commit()

def get_user_logs(db: Session, user_id: int):
    return db.query(UserSettingsLog).filter(UserSettingsLog.user_id == user_id).all()


def authenticate_user(db: Session, username: str, password: str):
    user = db.query(User).filter(User.username == username).first()
    if not user or password != user.password:
        return None
    return user
