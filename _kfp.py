import kfp
import sys
import datetime

namespace = 'kubeflow-anonymous'
experiment_name = sys.argv[1]
pipeline_path = f'ml/{experiment_name}/workflow.yaml'
datetime_now = f"{datetime.datetime.now():%Y%m%d_%H%M%S}"
job_name=f'{experiment_name}_training_{datetime_now}'

client = kfp.Client()
exp = client.create_experiment(name=f'{experiment_name}-9')
run = client.run_pipeline(experiment_id=exp.id,job_name=job_name,pipeline_package_path=pipeline_path)

print(run.id)
