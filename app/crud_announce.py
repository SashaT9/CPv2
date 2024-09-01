from fastapi import HTTPException
from sqlalchemy.orm import Session
from . import models, schemas

def create_announcement(db: Session, announcement: schemas.AnnouncementCreate, user_id: int):
    # Ensure the user is an admin
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user or not user.is_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    new_announcement = models.Announcement(**announcement.dict())
    db.add(new_announcement)
    db.commit()
    db.refresh(new_announcement)
    return new_announcement

def get_announcements(db: Session, announcement_id: int):
    # Fetch the announcement by ID
    announcement = db.query(models.Announcement).filter(models.Announcement.announcement_id == announcement_id).first()

    # Check if the announcement exists
    if announcement is None:
        raise HTTPException(status_code=404, detail="Announcement not found")

    # Check if the announcement is associated with any contest
    contest_association = db.query(models.ContestAnnouncement).filter(models.ContestAnnouncement.announcement_id == announcement_id).first()

    if contest_association is not None:
        # If the announcement is associated with a contest, raise an error indicating that
        raise HTTPException(status_code=400, detail="This announcement is associated with a contest and cannot be retrieved as a non-contest announcement")

    return announcement

def update_announcement(db: Session, announcement_id: int, announcement_data: schemas.AnnouncementCreate, user_id: int):
    # Ensure the user is an admin
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user or not user.is_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    announcement = db.query(models.Announcement).filter(models.Announcement.announcement_id == announcement_id).first()
    if announcement is None:
        raise HTTPException(status_code=404, detail="Announcement not found")

    # Update the announcement
    announcement.title = announcement_data.title
    announcement.content = announcement_data.content

    db.commit()
    db.refresh(announcement)
    return announcement

def delete_announcement(db: Session, announcement_id: int, user_id: int):
    # Ensure the user is an admin
    user = db.query(models.User).filter(models.User.user_id == user_id).first()
    if not user or not user.is_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    announcement = db.query(models.Announcement).filter(models.Announcement.announcement_id == announcement_id).first()
    if announcement is None:
        raise HTTPException(status_code=404, detail="Announcement not found")

    db.delete(announcement)
    db.commit()
    return announcement
