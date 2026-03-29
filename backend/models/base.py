from datetime import datetime
import json

class SerialMixin:
    """Mixin to provide automated dictionary serialization for SQLAlchemy models."""
    
    def to_dict(self):
        """Convert SQLAlchemy model instance to a dictionary."""
        result = {}
        for column in self.__table__.columns:
            value = getattr(self, column.name)
            
            # Handle datetime objects
            if isinstance(value, datetime):
                result[column.name] = value.isoformat()
            else:
                result[column.name] = value
                
        return result
