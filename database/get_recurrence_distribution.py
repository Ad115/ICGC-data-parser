import pony.orm as p

# < -- Setup the database schema ORM models

from schema_definition import *

# < -- Connect to the database (imported from schema definition)

db.bind(provider='sqlite', filename='mutations_test.sqlite')
db.generate_mapping()

# < -- Get the recurrence distribution

with p.db_session:
    query = p.select( (o.affected_donors, count(o)) for o in OccurrenceGlobal )
    query.show()
    recurrence = list(query)
    #Mutation.select().show()
	#Consequence.select().show()
	#OccurrenceGlobal.select().show()
	#OccurrenceByProject.select().show()

# < -- Plot the distribution

import seaborn as sns
import matplotlib.pyplot as plt

print(recurrence)

x = [ point[0] for point in recurrence ]
y = [ point[1] for point in recurrence ]

plt.plot(x, y)
plt.show()
