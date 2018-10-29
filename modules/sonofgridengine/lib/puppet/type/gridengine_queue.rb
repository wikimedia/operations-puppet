# Copyright 2018 Brooke Storm
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Puppet::Type.newtype(:gridengine_queue) do
    desc 'Resource type to manage gridengine queues. See sge_queue_conf(5)'

    ensurable

    newparam(:qname) do
        isnamevar
    end

    newproperty(:hostlist) do
        desc "The hostslists that access this queue for execution.
        This is a list of host identifiers per sge_types(1)"
    end

    newproperty(:seq_no) do
        desc "An integer that affects queue scheduling order (see sched_conf(5))"
        defaultto 0
    end

    newproperty(:load_thresholds) do
        desc "A list of load thresholds (see sge_queue_conf(5)) -- if any are reached, the task doesn't get scheduled"
        defaultto 'np_load_avg=1.75'
    end

    newproperty(:suspend_thresholds) do
        desc "A list of load thresholds -- if any are reached, the task gets suspended"
        defaultto 'NONE'
    end

    newproperty(:nsuspend) do
        desc "number of jobs to suspend if a suspend threshold is reached"
        defaultto 1
    end

    newproperty(:suspend_interval) do
        desc "Time to wait until more suspensions after nsuspend is done. The syntax is
        a time_specifier in sge_types(5)"
        defaultto '00:05:00'
    end

    newproperty(:priority) do
        desc "A nice(2) value.  However, this may ore may not do anything (see sge_queue_conf(5))"
        defaultto 0
    end

    newproperty(:min_cpu_interval) do
        desc "Time between two automatic checkpoints in case of transparently checkpointing jobs.
        Also time_specifier in sge_types(5)."
        defaultto '00:05:00'
    end

    newproperty(:processors) do
        desc "Binds a number of processors to this queue.  See sge_queue_conf(5) for more info"
        defaultto 'UNDEFINED'
    end

    newproperty(:qtype) do
        desc "Type of queue.  Can be BATCH, INTERACTIVE or an array of both.  It can also be NONE."

        newvalues('BATCH', 'INTERACTIVE', ['BATCH', 'INTERACTIVE'], 'NONE')
        defaultto ['BATCH', 'INTERACTIVE']
    end

    newproperty(:pe_list) do
        desc "A defined parallel environment."
        defaultto 'NONE'
    end

    newproperty(:ckpt_list) do
        desc "The list of administrator-defined checkpointing interface names."
        defaultto 'NONE'
    end

    newproperty(:rerun) do
        desc "Default behavior when a job fails. Restart or not.  Type is boolean."
        defaultto false
    end

    newproperty(:slots) do
        desc "Maximium concurrent slots that can be scheduled on a queue instance"
        defaultto 50
    end

    newproperty(:tmpdir) do
        desc "Directory for temp files while running a job"
        defaultto '/tmp'
    end

    newproperty(:shell) do
        desc "Shell to run jobs under"
        defaultto '/bin/bash'
    end

    newproperty(:prolog) do
        desc "Things to run before jobs in this queue"
        defaultto 'NONE'
    end

    newproperty(:epliog) do
        desc "Things to run after jobs in this queue"
        defaultto 'NONE'
    end

    newproperty(:shell_start_mode) do
        defaultto 'unix_behavior'
    end

    newproperty(:starter_method) do
        defaultto 'NONE'
    end

    newproperty(:suspend_method) do
        defaultto 'NONE'
    end

    newproperty(:resume_method) do
        defaultto 'NONE'
    end

    newproperty(:terminate_method) do
        defaultto '/usr/local/bin/jobkill $job_pid'
    end

    newproperty(:notify) do
        defaultto '00:00:60'
    end

    newproperty(:ownerlist) do
        defaultto 'NONE'
    end

    newproperty(:userlists) do
        defaultto 'NONE'
    end

    newproperty(:xuserlists) do
        defaultto 'NONE'
    end

    newproperty(:subordinate_list) do
        defaultto 'NONE'
    end

    newproperty(:complex_values) do
        defaultto 'NONE'
    end

    newproperty(:projects) do
        defaultto 'NONE'
    end

    newproperty(:xprojects) do
        defaultto 'NONE'
    end

    newproperty(:calendar) do
        defaultto 'NONE'
    end

    newproperty(:initial_state) do
        defaultto 'NONE'
    end

    newproperty(:s_rt) do
        defaultto 'INFINITY'
    end

    newproperty(:h_rt) do
        defaultto 'INFINITY'
    end

    newproperty(:s_cpu) do
        defaultto 'INFINITY'
    end

    newproperty(:h_cpu) do
        defaultto 'INFINITY'
    end

    newproperty(:s_fsize) do
        defaultto 'INFINITY'
    end

    newproperty(:h_fsize) do
        defaultto 'INFINITY'
    end

    newproperty(:s_data) do
        defaultto 'INFINITY'
    end

    newproperty(:h_data) do
        defaultto 'INFINITY'
    end

    newproperty(:s_stack) do
        defaultto 'INFINITY'
    end

    newproperty(:h_stack) do
        defaultto 'INFINITY'
    end

    newproperty(:s_core) do
        defaultto 'INFINITY'
    end

    newproperty(:h_core) do
        defaultto 'INFINITY'
    end

    newproperty(:s_rss) do
        defaultto 'INFINITY'
    end

    newproperty(:h_rss) do
        defaultto 'INFINITY'
    end

    newproperty(:s_vmem) do
        defaultto 'INFINITY'
    end

    newproperty(:h_vmem) do
        defaultto 'INFINITY'
    end
end
