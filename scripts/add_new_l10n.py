import sys

NEW_KEYS = {
    'filterPeopleOnly': {
        'es': 'Personas',
        'en': 'People',
        'pt': 'Pessoas',
        'fr': 'Personnes',
        'it': 'Persone',
        'de': 'Personen',
    },
    'genderLabel': {
        'es': 'Género',
        'en': 'Gender',
        'pt': 'Gênero',
        'fr': 'Genre',
        'it': 'Genere',
        'de': 'Geschlecht',
    },
    'genderFemale': {
        'es': 'Femenino',
        'en': 'Female',
        'pt': 'Feminino',
        'fr': 'Féminin',
        'it': 'Femminile',
        'de': 'Weiblich',
    },
    'genderMale': {
        'es': 'Masculino',
        'en': 'Male',
        'pt': 'Masculino',
        'fr': 'Masculin',
        'it': 'Maschile',
        'de': 'Männlich',
    },
    'genderNonBinary': {
        'es': 'No binario',
        'en': 'Non-binary',
        'pt': 'Não binário',
        'fr': 'Non binaire',
        'it': 'Non binario',
        'de': 'Nicht-binär',
    },
    'genderPreferNotToSay': {
        'es': 'Prefiero no decir',
        'en': 'Prefer not to say',
        'pt': 'Prefiro não dizer',
        'fr': 'Je préfère ne pas le dire',
        'it': 'Preferisco non dirlo',
        'de': 'Keine Angabe',
    },
    'cancelApplication': {
        'es': 'Cancelar postulación',
        'en': 'Cancel application',
        'pt': 'Cancelar candidatura',
        'fr': 'Annuler la candidature',
        'it': 'Annulla candidatura',
        'de': 'Bewerbung zurückziehen',
    },
    'cancelApplicationConfirm': {
        'es': '¿Deseás cancelar tu postulación a este Círculo?',
        'en': 'Do you want to cancel your application to this Circle?',
        'pt': 'Deseja cancelar sua candidatura a este Círculo?',
        'fr': 'Voulez-vous annuler votre candidature à ce Cercle ?',
        'it': 'Vuoi annullare la tua candidatura a questo Cerchio?',
        'de': 'Möchtest du deine Bewerbung für diesen Kreis zurückziehen?',
    },
    'applicationCanceledSuccess': {
        'es': 'Postulación cancelada con éxito.',
        'en': 'Application canceled successfully.',
        'pt': 'Candidatura cancelada com sucesso.',
        'fr': 'Candidature annulée avec succès.',
        'it': 'Candidatura annullata con successo.',
        'de': 'Bewerbung erfolgreich zurückgezogen.',
    },
    'exitOnboardingConfirm': {
        'es': '¿Deseás salir de la creación de tu perfil?',
        'en': 'Do you want to exit profile setup?',
        'pt': 'Deseja sair da criação do seu perfil?',
        'fr': 'Voulez-vous quitter la création de votre profil ?',
        'it': 'Vuoi uscire dalla creazione del tuo profilo?',
        'de': 'Möchtest du die Profilerstellung beenden?',
    },
    'tabMyCircles': {
        'es': 'Mis Círculos',
        'en': 'My Circles',
        'pt': 'Meus Círculos',
        'fr': 'Mes Cercles',
        'it': 'I Miei Cerchi',
        'de': 'Meine Kreise',
    },
    'tabApplications': {
        'es': 'Postulaciones',
        'en': 'Applications',
        'pt': 'Candidaturas',
        'fr': 'Candidatures',
        'it': 'Candidature',
        'de': 'Bewerbungen',
    },
    'noApplicationsTitle': {
        'es': 'No tenés postulaciones activas',
        'en': 'No active applications',
        'pt': 'Nenhuma candidatura ativa',
        'fr': 'Aucune candidature active',
        'it': 'Nessuna candidatura ativa',
        'de': 'Keine aktiven Bewerbungen',
    },
    'noApplicationsSubtitle': {
        'es': 'Cuando te postules o des like a un Círculo en expansión, aparecerá acá para que puedas seguirlo o cancelarlo.',
        'en': 'When you apply or like an expanding Circle, it will appear here so you can track or cancel it.',
        'pt': 'Quando você se candidatar ou der like em um Círculo em expansão, ele aparecerá aqui para você acompanhar ou cancelar.',
        'fr': 'Lorsque vous postulez ou aimez un Cercle en expansion, il apparaîtra ici pour que vous puissiez le suivre ou l\'annuler.',
        'it': 'Quando ti candidi o metti mi piace a un Cerchio in espansione, apparirà qui per monitorarlo o annullarlo.',
        'de': 'Wenn du dich für einen Kreis bewirbst oder ihn likest, wird er hier angezeigt, damit du ihn verfolgen oder zurückziehen kannst.',
    },
    'statusEvaluating': {
        'es': 'En evaluación',
        'en': 'Under review',
        'pt': 'Em avaliação',
        'fr': 'En cours d\'évaluation',
        'it': 'In valutazione',
        'de': 'In Prüfung',
    },
    'themeAutoSubtitle': {
        'es': 'Sigue la configuración de tu teléfono',
        'en': 'Follows system settings',
        'pt': 'Segue a configuração do seu telefone',
        'fr': 'Suit les paramètres du système',
        'it': 'Segue le impostazioni di sistema',
        'de': 'Folgt den Systemeinstellungen',
    },
    'fillRequiredFields': {
        'es': 'Por favor completá los campos obligatorios.',
        'en': 'Please fill in all required fields.',
        'pt': 'Por favor preencha os campos obrigatórios.',
        'fr': 'Veuillez remplir les champs obligatoires.',
        'it': 'Si prega di compilare i campi obbligatori.',
        'de': 'Bitte fülle alle Pflichtfelder aus.',
    },
    'passwordMinLength': {
        'es': 'La contraseña debe tener al menos 6 caracteres.',
        'en': 'Password must be at least 6 characters.',
        'pt': 'A senha deve ter pelo menos 6 caracteres.',
        'fr': 'Le mot de passe doit comporter au moins 6 caractères.',
        'it': 'La password deve contenere almeno 6 caratteri.',
        'de': 'Das Passwort muss mindestens 6 Zeichen lang sein.',
    },
    'selectMinInterests': {
        'es': 'Por favor seleccioná al menos 3 intereses.',
        'en': 'Please select at least 3 interests.',
        'pt': 'Por favor selecione pelo menos 3 interesses.',
        'fr': 'Veuillez sélectionner au moins 3 centres d\'intérêt.',
        'it': 'Seleziona almeno 3 interessi.',
        'de': 'Bitte wähle mindestens 3 Interessen aus.',
    },
    'fillEmailAndPassword': {
        'es': 'Por favor completá tu correo y contraseña.',
        'en': 'Please enter your email and password.',
        'pt': 'Por favor informe seu e-mail e senha.',
        'fr': 'Veuillez saisir votre e-mail et votre mot de passe.',
        'it': 'Inserisci la tua email e password.',
        'de': 'Bitte gib deine E-Mail und dein Passwort ein.',
    },
    'swipeUndoneSuccess': {
        'es': 'Swipe deshecho con éxito',
        'en': 'Swipe undone successfully',
        'pt': 'Swipe desfeito com sucesso',
        'fr': 'Swipe annulé avec succès',
        'it': 'Swipe annullato con successo',
        'de': 'Swipe erfolgreich rückgängig gemacht',
    },
    'duoLinkedSuccess': {
        'es': '¡Dupla vinculada con éxito!',
        'en': 'Duo linked successfully!',
        'pt': 'Dupla vinculada com sucesso!',
        'fr': 'Duo associé avec succès !',
        'it': 'Coppia collegata con successo!',
        'de': 'Duo erfolgreich verknüpft!',
    },
    'allRegions': {
        'es': 'Todas las regiones',
        'en': 'All regions',
        'pt': 'Todas as regiões',
        'fr': 'Toutes les régions',
        'it': 'Tutte le regioni',
        'de': 'Alle Regionen',
    },
}

path = "apps/circulo/lib/l10n/app_localizations.dart"
with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()

new_lines = []
current_lang = None

for line in lines:
    for lang in ['es', 'en', 'pt', 'fr', 'it', 'de']:
        if line.strip().startswith(f"'{lang}': {{"):
            current_lang = lang
            break
    
    if current_lang and "'swipeToContinue':" in line:
        new_lines.append(line)
        # Append new keys right after swipeToContinue
        for k, trans in NEW_KEYS.items():
            val = trans[current_lang].replace("'", "\\'")
            new_lines.append(f"      '{k}': '{val}',\n")
        current_lang = None
    else:
        new_lines.append(line)

with open(path, "w", encoding="utf-8") as f:
    f.writelines(new_lines)

print(f"Successfully processed app_localizations.dart.")
