from sqlalchemy.orm import Session
from . import models, schemas
def get_users(db: Session):
    return db.query(models.User).all()

def create_user(db: Session, user: schemas.UserCreate):
    password = user.password
    db_user = models.User(username=user.username, password=password, email=user.email, role=user.role)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

def delete_user(db: Session, user_id: int):
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if user:
        db.delete(user)
        db.commit()
        return True
    return False

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