using Gee;

namespace IntaText.AI {
    public class AIModelList : Object {
        private Gee.ArrayList<AIModelInfo> models = new Gee.ArrayList<AIModelInfo>();

        public Gee.ArrayList<AIModelInfo> get_models() {
            return models;
        }

        public void add_model(AIModelInfo model) {
            models.add(model);
        }

        public void clear() {
            models.clear();
        }
    }
}