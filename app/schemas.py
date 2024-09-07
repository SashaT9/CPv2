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
    output_only: bool = True

    class Config:
        orm_mode = True


class ProblemCreate(BaseModel):
    statement: str
    answer: str
    output_only: bool = True

class ProblemUpdate(BaseModel):
    statement: str
    answer: str

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


class SolutionCreate(BaseModel):
    answer: str

class SubmissionCreate(BaseModel):
    problem_id: int
    answer: str


class SubmissionResponse(BaseModel):
    answer: str
    problem_id: int
    status: str



class Contest(BaseModel):
    contest_id: int
    contest_name: str
    start_time: datetime
    end_time: datetime
    description: str

    class Config:
        orm_mode = True

class ContestCreate(BaseModel):
    contest_name: str
    start_time: datetime
    end_time: datetime
    description: str

class ContestParticipantBase(BaseModel):
    contest_id: int
    user_id: int
    score: int

class ContestParticipantCreate(ContestParticipantBase):
    pass

class ContestParticipant(ContestParticipantBase):
    class Config:
        orm_mode = True

class ContestParticipantWithUser(BaseModel):
    contest_id: int
    user_id: int
    score: int
    username: str  # Ensure this field is included

    class Config:
        orm_mode = True



class ContestAddProblem(BaseModel):
    problem_id: int

class ContestProblem(BaseModel):
    contest_id: int
    problem_id: int
    class Config:
        orm_mode = True

class ContestAnnouncementBase(BaseModel):
    contest_id: int
    announcement_id: int

class ContestAnnouncement(ContestAnnouncementBase):
    class Config:
        orm_mode = True