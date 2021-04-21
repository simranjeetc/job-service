/*
 * Copyright 2016-2021 Micro Focus or one of its affiliates.
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
package com.hpe.caf.services.job.utilities;

import com.hpe.caf.services.job.api.generated.model.DeletePolicy;
import com.hpe.caf.services.job.api.generated.model.DeletePolicy.OperationEnum;
import com.hpe.caf.services.job.api.generated.model.ExpirationPolicy;
import com.hpe.caf.services.job.api.generated.model.NewJob;
import com.hpe.caf.services.job.api.generated.model.Policy;
import com.hpe.caf.services.job.exceptions.BadRequestException;
import org.junit.Before;
import org.junit.Test;

import static org.junit.jupiter.api.Assertions.assertAll;
import static org.testng.Assert.*;

public class PolicyBuilderTest{

    final NewJob job = new NewJob();
    final Policy userDefaultPolicy = new Policy();
    final Policy systemDefaultPolicy = new Policy();
    final DeletePolicy defaultDeletePolicy = new DeletePolicy();

    @Before
    public void init(){
        systemDefaultPolicy.setOperation(Policy.OperationEnum.EXPIRE);
        systemDefaultPolicy.setExpiryTime("createTime+P90M+System");
        userDefaultPolicy.setOperation(Policy.OperationEnum.EXPIRE);
        userDefaultPolicy.setExpiryTime("none");
        defaultDeletePolicy.setOperation(OperationEnum.DELETE);
        defaultDeletePolicy.setExpiryTime("none");
    }

    @Test
    public void fillUserDefaultPolicyWhenMissing() throws BadRequestException {
        // Set partial policy
        final ExpirationPolicy expirationPolicy = new ExpirationPolicy();
        expirationPolicy.setDefault(userDefaultPolicy);
        final Policy activePolicy = new Policy();
        activePolicy.setExpiryTime("none");
        activePolicy.setOperation(Policy.OperationEnum.DELETE);
        expirationPolicy.setActive(activePolicy);
        final DeletePolicy completedPolicy = new DeletePolicy();
        completedPolicy.setExpiryTime("createTime+PT1H");
        completedPolicy.setOperation(OperationEnum.DELETE);
        expirationPolicy.setCompleted(completedPolicy);
        job.setExpiry(expirationPolicy);

        PolicyBuilder.buildPolicyMap(job);

        assertAll(
                ()-> assertEquals(activePolicy, job.getExpiry().getActive()),
                ()-> assertEquals(completedPolicy, job.getExpiry().getCompleted()),
                ()-> assertEquals(userDefaultPolicy, job.getExpiry().getPaused()),
                ()-> assertEquals(userDefaultPolicy, job.getExpiry().getWaiting()),
                ()-> assertEquals(defaultDeletePolicy, job.getExpiry().getExpired())
        );
    }

    @Test
    public void fillSystemDefaultPolicyWhenMissing() throws BadRequestException {
        // Set partial policy
        final ExpirationPolicy expirationPolicy = new ExpirationPolicy();
        final Policy activePolicy = new Policy();
        activePolicy.setExpiryTime("none");
        activePolicy.setOperation(Policy.OperationEnum.DELETE);
        expirationPolicy.setActive(activePolicy);
        final DeletePolicy completedPolicy = new DeletePolicy();
        completedPolicy.setExpiryTime("createTime+PT1H");
        completedPolicy.setOperation(OperationEnum.DELETE);
        expirationPolicy.setCompleted(completedPolicy);
        job.setExpiry(expirationPolicy);

        PolicyBuilder.buildPolicyMap(job);

        assertAll(
                ()-> assertEquals(activePolicy, job.getExpiry().getActive()),
                ()-> assertEquals(completedPolicy, job.getExpiry().getCompleted()),
                ()-> assertEquals(systemDefaultPolicy, job.getExpiry().getPaused()),
                ()-> assertEquals(systemDefaultPolicy, job.getExpiry().getWaiting()),
                ()-> assertEquals(defaultDeletePolicy, job.getExpiry().getExpired())
        );
    }

    @Test
    public void fillDefaultPolicyWhenEmpty() throws BadRequestException {

        PolicyBuilder.buildPolicyMap(job);

        assertAll(
                ()-> assertEquals(systemDefaultPolicy, job.getExpiry().getActive()),
                ()-> assertEquals(systemDefaultPolicy, job.getExpiry().getPaused()),
                ()-> assertEquals(systemDefaultPolicy, job.getExpiry().getWaiting()),
                ()-> assertEquals(defaultDeletePolicy, job.getExpiry().getExpired())
        );
    }
}
