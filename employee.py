from pydantic import BaseModel
from typing import Optional

class Employee(BaseModel):
    id: Optional[int] = None
    name: str
    age: int
    email: str