from sqlalchemy.orm import Session
from . import models, schemas
def get_users(db: Session):
    return db.query(models.User).all()

def create_user(db: Session, user: schemas.UserCreate):
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user:
        return None

    password = user.password.encode('utf-8')
    db_user = models.User(username=user.username, password=password, email=user.email, role="user")
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user