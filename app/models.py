from sqlalchemy import Column, Integer, String, Boolean, Text, ForeignKey, TIMESTAMP, func
from sqlalchemy.orm import relationship
from .database import Base

class User(Base):
    __tablename__ = 'users'
    user_id = Column(Integer, primary_key=True, index=True)
    username = Column(Text, unique=True, nullable=False)
    password = Column(Text)
    email = Column(Text, unique=True, nullable=False)
    role = Column(Text, nullable=False, default='user')

    @property
    def is_admin(self) -> bool:
        return self.role == 'admin'

class UserAchievement(Base):
    __tablename__ = 'user_achievements'
    user_id = Column(Integer, ForeignKey('users.user_id'), primary_key=True)
    problems_solve = Column(Integer)
    max_performance = Column(Integer)
    rating = Column(Integer)
    max_rating = Column(Integer)

class UserSettingsLog(Base):
    __tablename__ = 'user_settings_logs'
    user_id = Column(Integer, ForeignKey('users.user_id'), primary_key=True)
    date_of_change = Column(TIMESTAMP, default='current_timestamp')
    description = Column(Text)

class Topic(Base):
    __tablename__ = 'topics'
    topic_id = Column(Integer, primary_key=True)
    topic_name = Column(Text, unique=True, nullable=False)

class Problem(Base):
    __tablename__ = 'problems'
    problem_id = Column(Integer, primary_key=True)
    statement = Column(Text)
    answer = Column(Text)
    output_only = Column(Boolean, default=True)

class ProblemTopics(Base):
    __tablename__ = 'problems_topics'
    problem_id = Column(Integer, ForeignKey('problems.problem_id'), primary_key=True)
    topic = Column(Integer, ForeignKey('topics.topic_id'), primary_key=True)


class Solution(Base):
    __tablename__ = 'solutions'
    solution_id = Column(Integer, primary_key=True)
    answer = Column(Text)

class Submission(Base):
    __tablename__ = 'submissions'
    user_id = Column(Integer, ForeignKey('users.user_id'), primary_key=True)
    problem_id = Column(Integer, ForeignKey('problems.problem_id'), primary_key=True)
    solution_id = Column(Integer, ForeignKey('solutions.solution_id'), primary_key=True)
    status = Column(Text)

class Tutorial(Base):
    __tablename__ = 'tutorials'
    problem_id = Column(Integer, ForeignKey('problems.problem_id'), primary_key=True)
    user_id = Column(Integer, ForeignKey('users.user_id'), primary_key=True)
    tutorial = Column(Text)

class Contest(Base):
    __tablename__ = 'contests'
    contest_id = Column(Integer, primary_key=True)
    contest_name = Column(Text, nullable=False)
    start_time = Column(TIMESTAMP)
    end_time = Column(TIMESTAMP)
    description = Column(Text)
    is_active = Column(Boolean, default=True)

class ContestProblem(Base):
    __tablename__ = 'contest_problems'
    contest_id = Column(Integer, ForeignKey('contests.contest_id'), primary_key=True)
    problem_id = Column(Integer, ForeignKey('problems.problem_id'), primary_key=True)

class ContestParticipant(Base):
    __tablename__ = 'contest_participants'
    contest_id = Column(Integer, ForeignKey('contests.contest_id'), primary_key=True)
    user_id = Column(Integer, ForeignKey('users.user_id'), primary_key=True)
    score = Column(Integer)
    rank = Column(Integer)

class Announcement(Base):
    __tablename__ = 'announcements'
    announcement_id = Column(Integer, primary_key=True)
    title = Column(Text, nullable=False)
    content = Column(Text)
    date_posted = Column(TIMESTAMP, server_default=func.now())

class ContestAnnouncement(Base):
    __tablename__ = 'contest_announcements'
    contest_id = Column(Integer, ForeignKey('contests.contest_id'), primary_key=True)
    announcement_id = Column(Integer, ForeignKey('announcements.announcement_id'), primary_key=True)

class ContestFeedback(Base):
    __tablename__ = 'contest_feedback'
    contest_id = Column(Integer, ForeignKey('contests.contest_id'), primary_key=True)
    user_id = Column(Integer, ForeignKey('users.user_id'), primary_key=True)
    feedback = Column(Text)
    rating = Column(Integer)
    date_submitted = Column(TIMESTAMP, default='current_timestamp')
