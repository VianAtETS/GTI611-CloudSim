package org.cloudbus.cloudsim.examples.power.planetlab;

import java.io.IOException;

/**
 * Laboratoire 2 - Partie 4 : variante de LrrMmt pour le scenario 8.
 *
 * Identique a LrrMmt (politique d'allocation LRR + selection MMT),
 * mais applique le workload PlanetLab 20110306 au lieu de 20110303.
 * Seule la variable locale 'workload' change : le module cloudsim-examples
 * en amont reste non modifie.
 */
public class LrrMmt_S8 {

    public static void main(String[] args) throws IOException {
        boolean enableOutput = true;
        boolean outputToFile = false;
        String inputFolder = LrrMmt_S8.class.getClassLoader().getResource("workload/planetlab").getPath();
        String outputFolder = "output";
        String workload = "20110306"; // PlanetLab workload - scenario 8
        String vmAllocationPolicy = "lrr"; // Local Regression Robust (LRR)
        String vmSelectionPolicy = "mmt"; // MMT VM selection policy
        String parameter = "1.2"; // safety parameter of the LRR policy

        new PlanetLabRunner(
                enableOutput,
                outputToFile,
                inputFolder,
                outputFolder,
                workload,
                vmAllocationPolicy,
                vmSelectionPolicy,
                parameter);
    }
}
