# Meditation-and-SART-task
An ACT-R model that undergoes focused attention meditation, followed by the use of a SART task


ACT-R was the best choice for modeling this project because it simulates the outputs of human cognition in a way that closely aligns with empirical behavioral data. It not only predicts task performance (errors and reaction times), but also provides insight into the cognitive processes, such as attention shifts, memory retrieval, and decision-making. 

The model includes three memory states: task, metatask, and daydream. The task state involves retrieving a memory and performing the task (1 instance), while the metatask state reflects thinking about doing the task without acting on it (1 instance). The daydream state represents mind-wandering and occurs most frequently (20 instances).


The model processes memory chunks that represent either attentional tasks (breathing and focus) or instances of mind-wandering (daydreaming). A chunk in ACT-R is a unit of declarative knowledge (a structured data element) which is manipulated in the cognitive process. The model operates with two primary goal chunks (focus and wander), which determine the current cognitive state. In addition, the model as a whole uses memory chunks that represent different types of mental content, categorized into three types: task chunks, which store information about the current activity; metatask chunks, which track awareness of the task; and daydream chunks, which contain unrelated, mind-wandering thoughts.


To enable the model to "learn" to meditate, I incorporated spreading activation of memory chunks, utility values for productions, and utility learning mechanisms. When the focus chunk is in the goal buffer, the model should be more likely to retrieve Task and Metatask memories. To facilitate this, the goal buffer spreads activation to these memories, increasing their likelihood of retrieval. Similarly, when the goal shifts to wander, Daydream memories become more accessible due to the same activation process. This "learning" mechanism is activated when the Focus retrieval production requests a general memory. Since the Focus goal is in the goal buffer, spreading activation prioritizes Task and Metatask memories, making them more likely to be retrieved than Daydream memories. Additionally, productions are assigned utility values, meaning one production can be preferred over another. For instance, when the Metatask memory is about to be retrieved, both the Refresh focus and Daydream about intention productions are triggered. However, because the goal is to focus, the Refresh focus production should take precedence.


To simulate the SART task in the model, we disable the productions related to meditation, such as the feel breath production, and enable those specific to task performance. This includes additional productions like check stimulus-response (S-R), identify stimulus, and retrieve intention, which support the SART task execution. 

In a comparison of the FA meditation condition to the no meditation condition, the model was adjusted by modifying the activation level of the metatask memory and updating the utility values of the refresh and remember productions.