import Alpine from 'alpinejs'
window.Alpine = Alpine

Alpine.data('quizApp', () => ({
    currentIndex: 0,
    score: 0,
    selectedAnswer: null,
    showFeedback: false,
    quizFinished: false,
    donkeys: [],
    allNames: [],
    currentFoto: '', // DEZE ONTBRAK

    async init() {
        try {
            const response = await fetch('/ezies.json');
            this.donkeys = await response.json();
            this.donkeys.sort(() => 0.5 - Math.random());
            this.allNames = this.donkeys.map(d => d.naam);
            this.setRandomFoto();
        } catch (e) {
            console.error("Data kon niet laden", e);
        }
    },

    // Deze getter is nu veilig en simpel
    get currentImageUrl() {
        if (!this.donkeys.length || !this.currentFoto) return ''; 
        return 'images/optimized/' + this.currentFoto;
    },

    get currentOptions() {
        if (!this.donkeys.length || !this.donkeys[this.currentIndex]) return [];

        const correct = this.donkeys[this.currentIndex].naam; 
        const others = this.allNames
            .filter(n => n !== correct)
            .sort(() => 0.5 - Math.random())
            .slice(0, 2);

        return [correct, ...others].sort(() => 0.5 - Math.random());
    },

    checkAnswer(name) {
        if (this.showFeedback) return;
        this.selectedAnswer = name;
        this.showFeedback = true;
        if (name === this.donkeys[this.currentIndex].naam) this.score++;
    },

    nextQuestion() {
        if (this.currentIndex + 1 < this.donkeys.length) {
            this.currentIndex++;
            this.selectedAnswer = null;
            this.showFeedback = false;
            this.setRandomFoto();
        } else {
            this.quizFinished = true;
        }
    },

    setRandomFoto() {
        if (this.donkeys.length > 0) {
            const ezel = this.donkeys[this.currentIndex];
            const index = Math.floor(Math.random() * ezel.fotos.length);
            this.currentFoto = ezel.fotos[index];
        }
    },

    resetQuiz() {
        this.currentIndex = 0;
        this.score = 0;
        this.selectedAnswer = null;
        this.showFeedback = false;
        this.quizFinished = false;
        this.donkeys.sort(() => 0.5 - Math.random());
        this.setRandomFoto();
    }
}));

Alpine.start();
