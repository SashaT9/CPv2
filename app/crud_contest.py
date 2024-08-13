from sqlalchemy.orm import Session
from . import models, schemas

def create_contest(db: Session, contest: schemas.ContestCreate):
    db_contest = models.Contest(**contest.dict())
    db.add(db_contest)
    db.commit()
    db.refresh(db_contest)
    return db_contest

def get_contests(db: Session):
    return db.query(models.Contest).all()

def get_contest_by_id(db: Session, contest_id: int):
    return db.query(models.Contest).filter(models.Contest.contest_id == contest_id).first()

def update_contest(db: Session, contest_id: int, contest_update: schemas.ContestUpdate):
    db_contest = db.query(models.Contest).filter(models.Contest.contest_id == contest_id).first()
    if not db_contest:
        return None
    for key, value in contest_update.dict(exclude_unset=True).items():
        setattr(db_contest, key, value)
    db.commit()
    db.refresh(db_contest)
    return db_contest

def delete_contest(db: Session, contest_id: int):
    db_contest = db.query(models.Contest).filter(models.Contest.contest_id == contest_id).first()
    if db_contest:
        db.delete(db_contest)
        db.commit()
        return True
    return False
