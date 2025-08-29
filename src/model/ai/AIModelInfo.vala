namespace IntaText.AI {
    public enum AIModelProvider {
        OLLAMA,
        LLAMACPP
    }

    public class AIModelInfo : Object {
        public string name { get; set; }
        public AIModelProvider provider { get; set; }
        public string parameters { get; set; } // À adapter selon besoins

        public AIModelInfo(string name, AIModelProvider provider, string parameters = "") {
            this.name = name;
            this.provider = provider;
            this.parameters = parameters;
        }
    }
}