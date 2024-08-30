from sqlalchemy.orm import Session
from .models import Announcement
from .schemas import AnnouncementCreate

def create_announcement(db: Session, announcement_data: AnnouncementCreate):
    new_announcement = Announcement(**announcement_data.dict())
    db.add(new_announcement)
    db.commit()
    db.refresh(new_announcement)
    return new_announcement

def get_announcements(db: Session):
    return db.query(Announcement).order_by(Announcement.date_posted.desc()).all()
