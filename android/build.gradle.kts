allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// --- Contournement : API 37 indisponible pour AGP -----------------------------
// Le SDK local n'expose l'API 37 que comme « platforms;android-37.0 » (schéma
// « minor version » d'Android 17). AGP 9.0.1, en DSL hérité (android.newDsl=false),
// cherche le hash « android-37 » et échoue :
//   Failed to find target with hash string 'android-37' in: C:\Android\Sdk
// On aligne donc TOUS les modules — y compris ceux des plugins, dont
// flutter_secure_storage qui déclare compileSdk = 37 — sur l'API 36, la version
// par défaut de cette version de Flutter. Flutter, de son côté, n'écrase pas le
// compileSdk des plugins : il se contente d'un avertissement, donc cette
// configuration est bien appliquée sans bloquer le build.
//
// ATTENTION À L'ORDRE DES BLOCS : celui-ci doit rester AVANT le
// « subprojects { project.evaluationDependsOn(":app") } » plus bas.
// `evaluationDependsOn` évalue le projet ciblé de façon anticipée ; depuis
// Gradle 7 (ici 9.1.0), appeler `afterEvaluate` sur un projet déjà évalué lève :
//   Cannot run Project.afterEvaluate(Action) when the project is already evaluated.
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        val methods = androidExt.javaClass.methods
        val setCompileSdk =
            methods.firstOrNull { it.name == "setCompileSdk" && it.parameterCount == 1 }
        if (setCompileSdk != null) {
            runCatching { setCompileSdk.invoke(androidExt, 36) }
        } else {
            methods
                .firstOrNull { it.name == "setCompileSdkVersion" && it.parameterCount == 1 }
                ?.let { setter -> runCatching { setter.invoke(androidExt, "android-36") } }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
