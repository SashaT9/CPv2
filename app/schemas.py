from pydantic import BaseModel, conint, constr
from typing import Optional, List
from datetime import datetime

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


class UserDelete(BaseModel):
    username: str
    password: str

class UserUpdate(BaseModel):
    username: constr(min_length=1, max_length=50) | None = None
    password: constr(min_length=4) | None = None
    email: constr(max_length=100) | None = None

    class Config:
        orm_mode = True

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






# Contests schemas
class ContestBase(BaseModel):
    contest_name: str
    start_time: datetime
    end_time: datetime
    description: Optional[str] = None
    is_active: Optional[bool] = True

class ContestCreate(ContestBase):
    pass

class ContestUpdate(ContestBase):
    contest_name: Optional[str] = None
    start_time: Optional[datetime] = None
    end_time: Optional[datetime] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None

class Contest(ContestBase):
    contest_id: int

    class Config:
        orm_mode = True
