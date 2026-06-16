package org.cloudbus.cloudsim.examples;

import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.LinkedList;
import java.util.List;

import org.cloudbus.cloudsim.*;
import org.cloudbus.cloudsim.core.CloudSim;
import org.cloudbus.cloudsim.provisioners.BwProvisionerSimple;
import org.cloudbus.cloudsim.provisioners.PeProvisionerSimple;
import org.cloudbus.cloudsim.provisioners.RamProvisionerSimple;

public class partie2_E26 {

    private static final int NB_HOSTS = 4;
    private static final int NB_VMS = 6;
    private static final int NB_CLOUDLETS = 20;
    private static final int HOST_MIPS = 1500;
    private static final int HOST_PES = 3;
    private static final int VM_MIPS = 500;
    private static final int VM_PES = 2;
    private static final long CLOUDLET_LENGTH = 3000;

    public static void main(String[] args) throws Exception {
        runScenario(1, "SpaceShared (hotes) + SpaceShared (VMs)", false, false);
        runScenario(2, "SpaceShared (hotes) + TimeShared  (VMs)", false, true);
        runScenario(3, "TimeShared  (hotes) + SpaceShared (VMs)", true, false);
        runScenario(4, "TimeShared  (hotes) + TimeShared  (VMs)", true, true);
    }

    private static void runScenario(int num, String label, boolean hostTS, boolean vmTS)
            throws Exception {
        Log.printLine("\n========================================");
        Log.printLine("SCENARIO " + num + " : " + label);
        Log.printLine("========================================");

        CloudSim.init(1, Calendar.getInstance(), false);

        createDatacenter("Datacenter_0", hostTS);
        DatacenterBroker broker = new DatacenterBroker("Broker1");

        broker.submitVmList(createVMs(broker.getId(), vmTS));
        broker.submitCloudletList(createCloudlets(broker.getId()));

        CloudSim.startSimulation();
        List<Cloudlet> results = broker.getCloudletReceivedList();
        CloudSim.stopSimulation();

        printResults(results);
    }

    private static Datacenter createDatacenter(String name, boolean timeShared)
            throws Exception {
        List<Host> hosts = new ArrayList<>();
        for (int i = 0; i < NB_HOSTS; i++) {
            // Each host needs its own Pe list — never share Pe instances across hosts
            List<Pe> peList = new ArrayList<>();
            for (int j = 0; j < HOST_PES; j++) {
                peList.add(new Pe(j, new PeProvisionerSimple(HOST_MIPS)));
            }
            VmScheduler sched = timeShared
                    ? new VmSchedulerTimeShared(peList)
                    : new VmSchedulerSpaceShared(peList);
            hosts.add(new Host(i,
                    new RamProvisionerSimple(4096),
                    new BwProvisionerSimple(10000),
                    1_000_000,
                    peList,
                    sched));
        }

        DatacenterCharacteristics chars = new DatacenterCharacteristics(
                "x86", "Linux", "Xen", hosts, 10.0, 3.0, 0.05, 0.001, 0.0);
        return new Datacenter(name, chars,
                new VmAllocationPolicySimple(hosts), new LinkedList<>(), 0);
    }

    private static List<Vm> createVMs(int brokerId, boolean timeShared) {
        List<Vm> list = new ArrayList<>();
        for (int i = 0; i < NB_VMS; i++) {
            CloudletScheduler sched = timeShared
                    ? new CloudletSchedulerTimeShared()
                    : new CloudletSchedulerSpaceShared();
            list.add(new Vm(i, brokerId, VM_MIPS, VM_PES, 1024, 1000, 10_000, "Xen", sched));
        }
        return list;
    }

    private static List<Cloudlet> createCloudlets(int brokerId) {
        List<Cloudlet> list = new ArrayList<>();
        UtilizationModel um = new UtilizationModelFull();
        for (int i = 0; i < NB_CLOUDLETS; i++) {
            Cloudlet c = new Cloudlet(i, CLOUDLET_LENGTH, 1, 300, 300, um, um, um);
            c.setUserId(brokerId);
            list.add(c);
        }
        return list;
    }

    private static void printResults(List<Cloudlet> list) {
        String indent = "    ";
        Log.printLine();
        Log.printLine("========== OUTPUT ==========");
        Log.printLine("Cloudlet ID" + indent + "STATUS" + indent
                + "DC ID" + indent + "VM ID" + indent
                + "Time" + indent + "Start" + indent + "Finish");

        DecimalFormat dft = new DecimalFormat("###.##");
        for (Cloudlet c : list) {
            Log.print(indent + c.getCloudletId() + indent + indent);
            if (c.getCloudletStatus() == Cloudlet.SUCCESS) {
                Log.printLine("SUCCESS" + indent
                        + c.getResourceId() + indent
                        + c.getVmId() + indent
                        + dft.format(c.getActualCPUTime()) + indent
                        + dft.format(c.getExecStartTime()) + indent
                        + dft.format(c.getFinishTime()));
            }
        }
    }
}
