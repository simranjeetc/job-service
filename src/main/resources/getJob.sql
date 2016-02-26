/*
 *  Name: get_job
 *
 *  Description:  Returns the job definition for the specified job.
 */
CREATE OR REPLACE FUNCTION get_job(in_job_id VARCHAR(48))
  RETURNS TABLE ( job_id VARCHAR(48), name VARCHAR(255), description TEXT, data TEXT, create_date TIMESTAMP, status job_status, percentage_complete double precision, failure_details TEXT, actionType CHAR(6)) AS $$
BEGIN
  --  Raise exception if the job identifier has not been specified.
  IF in_job_id IS NULL OR in_job_id = '' THEN
    RAISE EXCEPTION 'Job identifier has not been specified';
  END IF;

  --  Return job metadata belonging to the specified job_id.
  --  'WORKER' is the only supported action type for now.
  RETURN QUERY
  SELECT job.job_id, job.name, job.description, job.data, job.create_date, job.status, job.percentage_complete, job.failure_details, CAST('WORKER' AS CHAR(6)) AS actionType
  FROM job WHERE job.job_id = in_job_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'job_id {%} not found', in_job_id;
  END IF;
END
$$ LANGUAGE plpgsql;