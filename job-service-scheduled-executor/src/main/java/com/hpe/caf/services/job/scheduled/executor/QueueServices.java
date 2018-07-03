/*
 * Copyright 2015-2018 Micro Focus or one of its affiliates.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.hpe.caf.services.job.scheduled.executor;

import com.hpe.caf.api.Codec;
import com.hpe.caf.api.CodecException;
import com.hpe.caf.api.worker.TaskMessage;
import com.hpe.caf.api.worker.TaskStatus;
import com.hpe.caf.api.worker.TrackingInfo;
import com.rabbitmq.client.Channel;
import com.rabbitmq.client.Connection;
import com.rabbitmq.client.MessageProperties;
import org.apache.commons.codec.binary.Base64;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.IOException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Collections;
import java.util.Date;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.TimeoutException;

/**
 * This class is responsible for sending task data to the target queue.
 */
public final class QueueServices
{
    private static final Logger LOG = LoggerFactory.getLogger(QueueServices.class);

    private final Connection connection;
    private final Channel publisherChannel;
    private final String targetQueue;
    private final Codec codec;

    public QueueServices(final Connection connection, final Channel publisherChannel, final String targetQueue, final Codec codec) {

        this.connection = connection;
        this.publisherChannel = publisherChannel;
        this.targetQueue = targetQueue;
        this.codec = codec;
    }

    /**
     * Send task data message to the target queue.
     *
     * @param   jobId               the job identifier
     * @param   workerAction        the worker task details
     * @throws IOException          thrown if message cannot be sent
     */
    public void sendMessage(final String jobId, final WorkerAction workerAction) throws IOException
    {
        //  Generate a random task id.
        LOG.debug("Generating task id ...");
        final String taskId = UUID.randomUUID().toString();

        //  Serialise the data payload. Encoding type is provided in the WorkerAction.
        final byte[] taskData;

        //  Check whether taskData is in the form of a string or object, and serialise/decode as appropriate.
        LOG.debug("Validating the task data ...");
        final Object taskDataObj = workerAction.getTaskData();
        
        if (taskDataObj instanceof String) {
            final String taskDataStr = (String) taskDataObj;
            final WorkerAction.TaskDataEncodingEnum encoding = workerAction.getTaskDataEncoding();

            if (encoding == null || encoding == WorkerAction.TaskDataEncodingEnum.UTF8) {
                taskData = taskDataStr.getBytes(StandardCharsets.UTF_8);
            } else if (encoding == WorkerAction.TaskDataEncodingEnum.BASE64) {
                taskData = Base64.decodeBase64(taskDataStr);
            } else {
                final String errorMessage = "Unknown taskDataEncoding";
                LOG.error(errorMessage);
                throw new RuntimeException(errorMessage);
            }
        } else if (taskDataObj instanceof Map<?, ?>) {
            try {
                taskData = codec.serialise(taskDataObj);
            } catch (final CodecException e) {
                final String errorMessage = "Failed to serialise TaskData";
                LOG.error(errorMessage);
                throw new RuntimeException(errorMessage, e);
            }
        } else {
            final String errorMessage = "The taskData is an unexpected type";
            LOG.error(errorMessage);
            throw new RuntimeException(errorMessage);
        }

        //  Set up string for statusCheckUrl
        final String statusCheckUrl = ScheduledExecutorConfig.getWebserviceUrl() +"/jobs/" + URLEncoder.encode(jobId, "UTF-8") +"/isActive";

        //  Construct the task message.
        LOG.debug("Constructing the task message ...");
        final TrackingInfo trackingInfo = new TrackingInfo(jobId, calculateStatusCheckDate(ScheduledExecutorConfig.getStatusCheckTime()),
                statusCheckUrl, ScheduledExecutorConfig.getTrackingPipe(), workerAction.getTargetPipe());

        final TaskMessage taskMessage = new TaskMessage(
                taskId,
                workerAction.getTaskClassifier(),
                workerAction.getTaskApiVersion(),
                taskData,
                TaskStatus.NEW_TASK,
                Collections.<String, byte[]>emptyMap(),
                targetQueue,
                trackingInfo);

        //  Serialise the task message.
        //  Wrap any CodecException as a RuntimeException as it shouldn't happen
        final byte[] taskMessageBytes;
        try {
            LOG.debug("Serialise the task message ...");
            taskMessageBytes = codec.serialise(taskMessage);
        } catch (final CodecException e) {
            LOG.error(e.getMessage());
            throw new RuntimeException(e);
        }

        //  Send the message.
        LOG.debug("Publishing the message ...");
        publisherChannel.basicPublish(
                "", targetQueue, MessageProperties.TEXT_PLAIN, taskMessageBytes);
    }

    /**
     * Calculates the date of the next status check to be performed.
     */
    private Date calculateStatusCheckDate(final String statusCheckTime){
        //make sure statusCheckTime is a valid long
        final long seconds;
        try{
            seconds = Long.parseLong(statusCheckTime);
        } catch (final NumberFormatException e) {
            final String errorMessage = "Please provide a valid integer for statusCheckTime in seconds. " + e;
            LOG.error(errorMessage);
            throw new RuntimeException(errorMessage);
        }

        //set up date for statusCheckTime. Get current date-time and add statusCheckTime seconds.
        final Instant now = Instant.now();
        final Instant later = now.plusSeconds(seconds);
        return Date.from( later );
    }

    /**
     * Closes the queue connection.
     * @throws Exception thrown if the queue connection cannot be closed.
     */
    public void close() throws Exception {
        try {
            //  Close channel.
            if (publisherChannel != null) {
                LOG.debug("Closing channel ...");
                publisherChannel.close();
            }

            //  Close connection.
            if (connection != null) {
                LOG.debug("Closing connection ...");
                connection.close();
            }

        } catch (IOException | TimeoutException e) {
            final String errorMessage = "Failed to close the queuing connection.";
            LOG.error(errorMessage);
            throw new RuntimeException(errorMessage);
        }
    }

}