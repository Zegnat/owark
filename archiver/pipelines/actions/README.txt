Pipelines in this directory are called by the scheduler.

Their name is the name of the corresponding action.

Inputs:

    * data: the action

Outputs: None

These pipelines must take care of removing the action from the queue once they are done.
