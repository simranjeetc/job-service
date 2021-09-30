--
-- Copyright 2016-2021 Micro Focus or one of its affiliates.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

/*
 *  Name: internal_drop_task_tables
 *
 *  Description:
 *  Drops all task tables belonging to the specified task and all its subtasks
 */

CREATE OR REPLACE PROCEDURE populate_delete_log_table (
    in_partition_id VARCHAR(40),
    in_task_id VARCHAR(70),
    query_count INTEGER default 0
)
    LANGUAGE plpgsql
AS $$
DECLARE
    task_table_ident TEXT;
    subtask_suffix TEXT;
    task_table_name VARCHAR;
    commit_limit integer:=10;

BEGIN
    -- Put together the task table identifier
    task_table_name := internal_get_task_table_name(in_partition_id, in_task_id);
--     raise notice 'task_table_name: %', task_table_name;
    task_table_ident = quote_ident(task_table_name);

    -- Check if the table exists
    IF internal_to_regclass(task_table_ident) IS NOT NULL THEN
        FOR subtask_suffix IN
            EXECUTE $ESC$SELECT '.' || subtask_id || CASE WHEN is_final THEN '*' ELSE '' END AS subtask_suffix FROM $ESC$ || task_table_ident
            loop
                query_count:= query_count + 1;
--                 raise notice 'query_count : %', query_count;
                if query_count >= commit_limit then
--                     raise notice 'Committing now : %', task_table_name;
                    commit;
                    query_count = 0;
                end if;
                call populate_delete_log_table(in_partition_id, in_task_id || subtask_suffix, query_count);
            END LOOP;

        -- Insert table name to be dropped 
        PERFORM internal_insert_delete_log(task_table_name);

    END IF;
    --   raise notice 'Committing now : %', task_table_name;
--   COMMIT;
END
$$;
