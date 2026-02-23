######################################################################################################
# SPDX-FileCopyrightText: Copyright (c) 2024-2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
######################################################################################################


from typing import List, Optional

from nemoguardrails import LLMRails
from nemoguardrails.embeddings.providers.base import EmbeddingModel
from nemoguardrails.embeddings.providers.registry import EmbeddingProviderRegistry
from nemoguardrails.llm.providers import register_llm_provider
from langchain_openai import ChatOpenAI


class OllamaEmbeddingModel(EmbeddingModel):
    """Embedding model using Ollama's OpenAI-compatible /v1/embeddings API.

    Works with any model served by Ollama (e.g. qwen3-embedding:4b).

    Args:
        embedding_model (str): The Ollama model name (e.g. 'qwen3-embedding:4b').
        base_url (str): Ollama OpenAI-compat base URL, e.g. 'http://localhost:11434/v1'.
        api_key (str): API key (Ollama accepts any non-empty string).
    """

    engine_name = "nim_patch"

    def __init__(
        self,
        embedding_model: str,
        base_url: Optional[str] = "http://localhost:11434/v1",
        api_key: Optional[str] = "ollama",
    ):
        try:
            from langchain_openai import OpenAIEmbeddings

            self.model = embedding_model
            self.document_embedder = OpenAIEmbeddings(
                model=embedding_model,
                openai_api_base=base_url,
                openai_api_key=api_key,
                check_embedding_ctx_length=False,
            )
        except ImportError:
            raise ImportError(
                "Could not import langchain_openai. Install it with "
                "`pip install langchain-openai`."
            )

    async def encode_async(self, documents: List[str]) -> List[List[float]]:
        """Async encode documents to embeddings."""
        return await self.document_embedder.aembed_documents(documents)

    def encode(self, documents: List[str]) -> List[List[float]]:
        """Encode documents to embeddings."""
        return self.document_embedder.embed_documents(documents)


def _get_embedding_model_parameters(config):
    """Return the parameters of models of type 'embeddings'."""
    embedding_parameters = []
    for model in config.models:
        if model.type == "embeddings":
            embedding_parameters.append(model.parameters)
    return embedding_parameters


def init(app: LLMRails):
    register_llm_provider("ollama_chat", ChatOpenAI)

    embedding_parameters = _get_embedding_model_parameters(app.config)

    if not embedding_parameters:
        raise ValueError("No embedding model parameters found in the configuration.")

    params = embedding_parameters[0]
    base_url = params.get("base_url", "http://localhost:11434/v1")
    api_key = params.get("api_key", "ollama")

    # Dynamically create a subclass with fixed Ollama connection params
    class FixedOllamaEmbeddingModel(OllamaEmbeddingModel):
        def __init__(self, embedding_model: str, **kwargs):
            # kwargs absorbs extra params (base_url, api_key) that NeMo Guardrails
            # passes from the config `parameters` block. We ignore them here and
            # use the values already captured in the closure above.
            super().__init__(embedding_model, base_url=base_url, api_key=api_key)

    FixedOllamaEmbeddingModel.__name__ = "FixedOllamaEmbeddingModel"

    if "nim_patch" not in EmbeddingProviderRegistry():
        app.register_embedding_provider(FixedOllamaEmbeddingModel, "nim_patch")
