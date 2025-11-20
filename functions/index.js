const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.linkCaregiverToPatient = functions.https.onCall(async (data, context) => {
    // Asegurarse de que el usuario esté autenticado
    if (!context.auth) {
        throw new functions.https.HttpsError(
            "unauthenticated",
            "Debe iniciar sesión para realizar esta acción."
        );
    }

    const caregiverId = context.auth.uid;
    const patientCode = data.patientCode;

    if (!patientCode) {
        throw new functions.https.HttpsError(
            "invalid-argument",
            "El código del paciente no fue proporcionado."
        );
    }

    const db = admin.firestore();

    try {
        // 1. Encontrar al paciente por su código de vinculación
        const patientQuery = await db.collection("users")
            .where("linkCode", "==", patientCode)
            .limit(1)
            .get();

        if (patientQuery.empty) {
            throw new functions.https.HttpsError(
                "not-found",
                "No se encontró ningún paciente con ese código."
            );
        }

        const patientDoc = patientQuery.docs[0];
        const patientId = patientDoc.id;
        const patientData = patientDoc.data();

        // 2. Verificar que el paciente no tenga ya un cuidador asignado
        if (patientData.caregiverId) {
            throw new functions.https.HttpsError(
                "already-exists",
                "El paciente ya está vinculado a otro cuidador."
            );
        }

        // 3. Vincular al cuidador y al paciente
        const caregiverRef = db.collection("users").doc(caregiverId);
        const patientRef = db.collection("users").doc(patientId);

        await db.runTransaction(async (transaction) => {
            transaction.update(caregiverRef, { patientId: patientId });
            transaction.update(patientRef, { caregiverId: caregiverId });
        });

        return { success: true, message: "¡Paciente y cuidador vinculados exitosamente!" };

    } catch (error) {
        console.error("Error al vincular cuidador y paciente:", error);
        if (error instanceof functions.https.HttpsError) {
            throw error; // Re-lanzar errores HttpsError
        }
        throw new functions.https.HttpsError(
            "internal",
            "Ocurrió un error interno al intentar vincular las cuentas."
        );
    }
});
