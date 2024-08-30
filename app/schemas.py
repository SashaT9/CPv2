from pydantic import BaseModel, conint, constr, EmailStr
from typing import Optional, List
from datetime import datetime

class TokenData(BaseModel):
    user_id: int

class Message(BaseModel):
    message: str

# User Schemas
class UserBase(BaseModel):
    username: str
    email: str
    role: str

class UserCreate(BaseModel):
    username: str
    password: str
    email: str

class UserLogin(BaseModel):
    username: str
    password: str

class UserResponse(BaseModel):
    id: int
    username: str
    role: str

    @property
    def is_admin(self) -> bool:
        return self.role == 'admin'

    class Config:
        orm_mode = True


class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None
    password: Optional[str] = None

class UserDelete(BaseModel):
    confirm: bool

class User(UserBase):
    user_id: int

    class Config:
        orm_mode = True

class UserLog(BaseModel):
    user_id: int
    date_of_change: datetime
    description: str

    class Config:
        orm_mode = True

# User Achievement Schemas

class UserAchievementBase(BaseModel):
    problems_solve: int
    max_performance: int
    rating: int
    max_rating: int

class UserAchievementCreate(UserAchievementBase):
    pass

class UserAchievement(UserAchievementBase):
    user_id: int

    class Config:
        orm_mode = True


class Problem(BaseModel):
    problem_id: int
    statement: str
    answer: str
    output_only: bool
    topic: int

    class Config:
        orm_mode = True


class ProblemCreate(BaseModel):
    statement: str
    answer: str
    output_only: bool = True
    topic: int


class AnnouncementCreate(BaseModel):
    title: str
    content: str

class Announcement(BaseModel):
    announcement_id: int
    title: str
    content: str
    date_posted: datetime

    class Config:
        orm_mode = True
