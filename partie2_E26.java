package org.cloudbus.cloudsim.examples;

import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.LinkedList;
import java.util.List;

import org.cloudbus.cloudsim.Cloudlet;
import org.cloudbus.cloudsim.CloudletScheduler;
import org.cloudbus.cloudsim.CloudletSchedulerSpaceShared;
import org.cloudbus.cloudsim.CloudletSchedulerTimeShared;
import org.cloudbus.cloudsim.Datacenter;
import org.cloudbus.cloudsim.DatacenterBroker;
import org.cloudbus.cloudsim.DatacenterCharacteristics;
import org.cloudbus.cloudsim.Host;
import org.cloudbus.cloudsim.Log;
import org.cloudbus.cloudsim.Pe;
import org.cloudbus.cloudsim.Storage;
import org.cloudbus.cloudsim.UtilizationModel;
import org.cloudbus.cloudsim.UtilizationModelFull;
import org.cloudbus.cloudsim.Vm;
import org.cloudbus.cloudsim.VmAllocationPolicySimple;
import org.cloudbus.cloudsim.VmScheduler;
import org.cloudbus.cloudsim.VmSchedulerSpaceShared;
import org.cloudbus.cloudsim.VmSchedulerTimeShared;
import org.cloudbus.cloudsim.core.CloudSim;
import org.cloudbus.cloudsim.provisioners.BwProvisionerSimple;
import org.cloudbus.cloudsim.provisioners.PeProvisionerSimple;
import org.cloudbus.cloudsim.provisioners.RamProvisionerSimple;

/**
 * Laboratoire 2 - Partie 2 : ordonnancement TS (Time-Shared) et SS
 * (Space-Shared).
 *
 * Scenario 1 (enonce) :
 * - 1 centre de donnees, 1 broker.
 * - 4 hotes, chacun 3 coeurs CPU de 1500 MIPS.
 * - 6 VMs, chacune 2 coeurs CPU de 500 MIPS.
 * - 20 cloudlets, chacune 3000 MI, 1 coeur, UtilizationModelFull.
 *
 * Deux niveaux d'ordonnancement, chacun SS ou TS, d'ou 4 scenarios :
 * Scenario | VM-sur-hote (VmScheduler) | Cloudlet-sur-VM (CloudletScheduler)
 * ---------+---------------------------+------------------------------------
 * 1 | Space-Shared | Space-Shared
 * 2 | Space-Shared | Time-Shared
 * 3 | Time-Shared | Space-Shared
 * 4 | Time-Shared | Time-Shared
 *
 * Usage : passer le numero de scenario en argument (1..4). Defaut : 1.
 * ./run.sh partie2_E26 -> scenario 1
 * ./run.sh "partie2_E26 2" -> scenario 2 (selon le wrapper run.sh)
 * Ou en specifiant la classe + arg via exec:java -Dexec.args="2".
 */
public class partie2_E26 {

    private static final int NB_HOSTS = 4;
    private static final int HOST_PES = 3;
    private static final int HOST_MIPS = 1500;

    private static final int NB_VMS = 6;
    private static final int VM_PES = 2;
    private static final int VM_MIPS = 500;

    private static final int NB_CLOUDLETS = 20;
    private static final long CLOUDLET_LENGTH = 3000;
    private static final int CLOUDLET_PES = 1;

    private static List<Cloudlet> cloudletList;
    private static List<Vm> vmlist;

    public static void main(String[] args) {
        // Selection du scenario (1..4). Voir tableau dans l'en-tete de classe.
        int scenario = 1;
        if (args != null && args.length > 0) {
            try {
                scenario = Integer.parseInt(args[0].trim());
            } catch (NumberFormatException ignored) {
                // garde la valeur par defaut
            }
        }
        boolean vmSchedTimeShared = (scenario == 3 || scenario == 4);
        boolean cloudletSchedTimeShared = (scenario == 2 || scenario == 4);

        Log.printLine("Starting partie2_E26 -- scenario " + scenario
                + " (VM-sur-hote=" + (vmSchedTimeShared ? "TS" : "SS")
                + ", Cloudlet-sur-VM=" + (cloudletSchedTimeShared ? "TS" : "SS") + ")");

        try {
            // Etape 1 : initialisation de la simulation.
            int num_user = 1;
            Calendar calendar = Calendar.getInstance();
            boolean trace_flag = false;
            CloudSim.init(num_user, calendar, trace_flag);

            // Etape 2 : centre de donnees.
            Datacenter datacenter0 = createDatacenter("Datacenter_0", vmSchedTimeShared);

            // Etape 3 : broker.
            DatacenterBroker broker = createBroker(1);
            int brokerId = broker.getId();

            // Etape 4 : VMs.
            vmlist = createVM(brokerId, NB_VMS, cloudletSchedTimeShared);
            broker.submitVmList(vmlist);

            // Etape 5 : cloudlets.
            cloudletList = createCloudlet(brokerId, NB_CLOUDLETS);
            broker.submitCloudletList(cloudletList);

            // Etape 6 : simulation.
            CloudSim.startSimulation();

            // Le placement VM->hote doit etre lu AVANT stopSimulation() :
            // apres l'arret, les VMs sont desallouees et getHost() renvoie null.
            // getVmsCreatedList() ne contient que les VMs reellement placees,
            // ce qui rend visible le cas SS ou seules 4 des 6 VMs tiennent.
            List<Vm> createdVms = broker.getVmsCreatedList();
            printVmAllocation(datacenter0, createdVms, vmlist.size());

            List<Cloudlet> receivedList = broker.getCloudletReceivedList();
            CloudSim.stopSimulation();

            // Resultats.
            Log.print("=============> User " + brokerId + "    ");
            printCloudletList(receivedList);

            Log.printLine("partie2_E26 (scenario " + scenario + ") finished!");
        } catch (Exception e) {
            e.printStackTrace();
            Log.printLine("The simulation has been terminated due to an unexpected error");
        }
    }

    /**
     * @param vmSchedTimeShared true => VmSchedulerTimeShared, false =>
     *                          VmSchedulerSpaceShared.
     *                          Controle l'ordonnancement des VMs au niveau de
     *                          l'hote.
     */
    private static Datacenter createDatacenter(String name, boolean vmSchedTimeShared) {
        List<Host> hostList = new ArrayList<Host>();

        int ram = 3072;
        long storage = 1000000;
        int bw = 10000;

        // Un hote par iteration. peList est recree pour chaque hote :
        // partager une meme instance de Pe entre plusieurs hotes fausse la
        // comptabilite des MIPS du provisioner.
        for (int hostId = 0; hostId < NB_HOSTS; hostId++) {
            List<Pe> peList = new ArrayList<Pe>();
            for (int pe = 0; pe < HOST_PES; pe++) {
                peList.add(new Pe(pe, new PeProvisionerSimple(HOST_MIPS)));
            }

            VmScheduler vmScheduler = vmSchedTimeShared
                    ? new VmSchedulerTimeShared(peList)
                    : new VmSchedulerSpaceShared(peList);

            hostList.add(new Host(
                    hostId,
                    new RamProvisionerSimple(ram),
                    new BwProvisionerSimple(bw),
                    storage,
                    peList,
                    vmScheduler));
        }

        String arch = "x86";
        String os = "Linux";
        String vmm = "Xen";
        double time_zone = 10.0;
        double cost = 3.0;
        double costPerMem = 0.05;
        double costPerStorage = 0.001;
        double costPerBw = 0.0;

        LinkedList<Storage> storageList = new LinkedList<Storage>();

        DatacenterCharacteristics characteristics = new DatacenterCharacteristics(
                arch, os, vmm, hostList, time_zone, cost, costPerMem, costPerStorage, costPerBw);

        Datacenter datacenter = null;
        try {
            datacenter = new Datacenter(
                    name, characteristics, new VmAllocationPolicySimple(hostList), storageList, 0);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return datacenter;
    }

    private static DatacenterBroker createBroker(int id) {
        DatacenterBroker broker = null;
        try {
            broker = new DatacenterBroker("Broker" + id);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return broker;
    }

    /**
     * @param cloudletSchedTimeShared true => CloudletSchedulerTimeShared,
     *                                false => CloudletSchedulerSpaceShared.
     *                                Controle l'ordonnancement
     *                                des cloudlets au niveau de la VM.
     */
    private static List<Vm> createVM(int userId, int vms, boolean cloudletSchedTimeShared) {
        LinkedList<Vm> list = new LinkedList<Vm>();

        long size = 10000;
        int ram = 1024;
        long bw = 1000;
        String vmm = "Xen";

        for (int i = 0; i < vms; i++) {
            CloudletScheduler scheduler = cloudletSchedTimeShared
                    ? new CloudletSchedulerTimeShared()
                    : new CloudletSchedulerSpaceShared();

            Vm vm = new Vm(i, userId, VM_MIPS, VM_PES, ram, bw, size, vmm, scheduler);
            list.add(vm);
        }
        return list;
    }

    private static List<Cloudlet> createCloudlet(int userId, int cloudlets) {
        LinkedList<Cloudlet> list = new LinkedList<Cloudlet>();

        long fileSize = 300;
        long outputSize = 300;
        UtilizationModel utilizationModel = new UtilizationModelFull();

        for (int i = 0; i < cloudlets; i++) {
            Cloudlet cloudlet = new Cloudlet(
                    i, CLOUDLET_LENGTH, CLOUDLET_PES, fileSize, outputSize,
                    utilizationModel, utilizationModel, utilizationModel);
            cloudlet.setUserId(userId);
            list.add(cloudlet);
        }
        return list;
    }

    /**
     * Affiche, pour chaque VM reellement placee, l'hote qui l'heberge
     * (question 3a). En mode VmSchedulerSpaceShared, certaines VMs peuvent ne
     * pas etre placees faute de coeurs libres : on les liste explicitement.
     *
     * @param createdVms     VMs effectivement creees/placees
     *                       (broker.getVmsCreatedList()).
     * @param requestedCount nombre total de VMs demandees, pour signaler les
     *                       manquantes.
     */
    private static void printVmAllocation(Datacenter datacenter, List<Vm> createdVms, int requestedCount) {
        String indent = "    ";
        Log.printLine();
        Log.printLine("========== PLACEMENT DES VMs ==========");
        Log.printLine("VMs demandees : " + requestedCount
                + " -- VMs placees : " + createdVms.size());
        Log.printLine("VM ID" + indent + "Host ID" + indent + "Datacenter ID");

        java.util.Set<Integer> placedIds = new java.util.HashSet<Integer>();
        for (Vm vm : createdVms) {
            placedIds.add(vm.getId());
            Host host = vm.getHost();
            String hostId = (host == null) ? "?" : String.valueOf(host.getId());
            Log.printLine(indent + vm.getId() + indent + indent + hostId
                    + indent + indent + datacenter.getId());
        }
        for (int id = 0; id < requestedCount; id++) {
            if (!placedIds.contains(id)) {
                Log.printLine(indent + id + indent + indent + "NON PLACEE"
                        + indent + indent + datacenter.getId());
            }
        }
    }

    private static void printCloudletList(List<Cloudlet> list) {
        int size = list.size();
        Cloudlet cloudlet;
        String indent = "    ";

        Log.printLine();
        Log.printLine("========== OUTPUT ==========");
        Log.printLine("Cloudlet ID" + indent + "STATUS" + indent
                + "Data center ID" + indent + "VM ID" + indent + "Time"
                + indent + "Start Time" + indent + "Finish Time");

        DecimalFormat dft = new DecimalFormat("###.##");
        for (int i = 0; i < size; i++) {
            cloudlet = list.get(i);
            Log.print(indent + cloudlet.getCloudletId() + indent + indent);

            if (cloudlet.getCloudletStatus() == Cloudlet.SUCCESS) {
                Log.print("SUCCESS");
                Log.printLine(indent + indent + cloudlet.getResourceId()
                        + indent + indent + indent + cloudlet.getVmId()
                        + indent + indent + dft.format(cloudlet.getActualCPUTime())
                        + indent + indent + dft.format(cloudlet.getExecStartTime())
                        + indent + indent + dft.format(cloudlet.getFinishTime()));
            }
        }
    }
}
