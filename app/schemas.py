from pydantic import BaseModel, conint
from typing import Optional, List
from datetime import datetime

class Message(BaseModel):
    message: str

# User Schemas
class UserBase(BaseModel):
    username: str
    email: str
    role: str

class UserCreate(UserBase):
    password: str

class UserDelete(BaseModel):
    username: str
    password: str


class User(UserBase):
    user_id: int

    class Config:
        orm_mode = True

# User Achievement Schemas
class UserAchievementBase(BaseModel):
    problems_solve: conint(ge=0) = 0
    max_performance: conint(ge=0) = 0
    rating: conint(ge=0) = 0
    max_rating: conint(ge=0) = 0

class UserAchievementCreate(UserAchievementBase):
    user_id: int

class UserAchievementUpdate(UserAchievementBase):
    pass

class UserAchievement(UserAchievementBase):
    user_id: int

    class Config:
        orm_mode = True

# User Settings Log Schemas
class UserSettingsLogBase(BaseModel):
    date_of_change: Optional[datetime] = datetime.now()
    description: Optional[str] = None

class UserSettingsLog(UserSettingsLogBase):
    user_id: int

    class Config:
        orm_mode = True

# Role Schemas
class RoleBase(BaseModel):
    role_name: str

class Role(RoleBase):
    role_id: int

    class Config:
        orm_mode = True

# UserRole Schemas
class UserRoleBase(BaseModel):
    user_id: int
    role_id: int

class UserRole(UserRoleBase):
    pass

    class Config:
        orm_mode = True

# Topic Schemas
class TopicBase(BaseModel):
    topic_name: str

class Topic(TopicBase):
    topic_id: int

    class Config:
        orm_mode = True

# Problem Schemas
class ProblemBase(BaseModel):
    statement: str
    answer: str
    output_only: Optional[bool] = True
    topic: int

class Problem(ProblemBase):
    problem_id: int

    class Config:
        orm_mode = True

# Solution Schemas
class SolutionBase(BaseModel):
    answer: str

class Solution(SolutionBase):
    solution_id: int

    class Config:
        orm_mode = True

# Submission Schemas
class SubmissionBase(BaseModel):
    user_id: int
    problem_id: int
    solution_id: int
    status: str

class Submission(SubmissionBase):
    pass

    class Config:
        orm_mode = True

# Tutorial Schemas
class TutorialBase(BaseModel):
    tutorial: str

class Tutorial(TutorialBase):
    problem_id: int
    user_id: int

    class Config:
        orm_mode = True

# Contest Schemas
class ContestBase(BaseModel):
    contest_name: str
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    description: Optional[str] = None
    is_active: Optional[bool] = True

class Contest(ContestBase):
    contest_id: int

    class Config:
        orm_mode = True

# Contest Problem Schemas
class ContestProblemBase(BaseModel):
    contest_id: int
    problem_id: int

class ContestProblem(ContestProblemBase):
    pass

    class Config:
        orm_mode = True

# Contest Participant Schemas
class ContestParticipantBase(BaseModel):
    contest_id: int
    user_id: int
    score: Optional[int] = 0
    rank: Optional[int] = 0

class ContestParticipant(ContestParticipantBase):
    pass

    class Config:
        orm_mode = True

# Announcement Schemas
class AnnouncementBase(BaseModel):
    title: str
    content: Optional[str] = None
    date_posted: Optional[datetime] = datetime.now()

class Announcement(AnnouncementBase):
    announcement_id: int

    class Config:
        orm_mode = True

# Contest Announcement Schemas
class ContestAnnouncementBase(BaseModel):
    contest_id: int
    announcement_id: int

class ContestAnnouncement(ContestAnnouncementBase):
    pass

    class Config:
        orm_mode = True

# Contest Feedback Schemas
class ContestFeedbackBase(BaseModel):
    contest_id: int
    user_id: int
    feedback: Optional[str] = None
    rating: Optional[int] = 0
    date_submitted: Optional[datetime] = datetime.now()

class ContestFeedback(ContestFeedbackBase):
    pass

    class Config:
        orm_mode = True
