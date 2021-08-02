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
 *  Name: report_failure
 *
 *  Description:
 *  Update the specified task and subsequent parent tasks/job with the failure details.
 */
DROP FUNCTION IF EXISTS report_failure(
    in_partition_id VARCHAR(40),
    in_task_id VARCHAR(58),
    in_short_task_id VARCHAR(58),
    in_failure_details TEXT
);
DROP FUNCTION IF EXISTS report_failure(
    in_partition_id VARCHAR(40),
    in_task_id VARCHAR(58),
    in_short_task_id VARCHAR(58),
    in_failure_details TEXT,
    in_propagate_failures BOOLEAN
);
DROP FUNCTION IF EXISTS report_failure(
    in_partition_id VARCHAR(40),
    in_task_id VARCHAR(58),
    in_failure_details TEXT,
    in_propagate_failures BOOLEAN
);
DROP FUNCTION IF EXISTS report_failure(
    in_partition_id VARCHAR(40),
    in_task_id VARCHAR(70),
    in_failure_details TEXT,
    in_propagate_failures BOOLEAN
);
DROP FUNCTION IF EXISTS report_failure(
    in_partition_id VARCHAR(40),
    in_task_id VARCHAR(70),
    in_failure_details TEXT
);
