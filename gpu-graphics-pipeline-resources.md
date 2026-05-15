# GPU 硬件与图形管线学习资源精选

> 来源: Reddit r/GraphicsProgramming、GitHub Awesome 系列公认最佳资源

---

## 一、GPU 硬件架构 🏆

### 1.1 经典必读（社区公认 Top 推荐）

| 资源 | 作者 | 链接 | 评价 |
|------|------|------|------|
| **A Trip Through the Graphics Pipeline** ★★★ | Fabian Giesen | [系列文章](https://fgiesen.wordpress.com/2011/07/09/a-trip-through-the-graphics-pipeline-2011-index/) | Reddit 最多推荐，深入浅出 |
| **Life of a Triangle - NVIDIA GTX 1080** ★★★ | NVIDIA | [Blog](https://developer.nvidia.com/content/life-triangle-nvidias-geforce-gtx-1080) | 从三角形角度看渲染管线 |
| **A Trip Down the Graphics Pipeline** ★★★ | Jim Blinn | [Book](http://www.amazon.com/dp/1558603875) | 经典书籍，管道核心概念 |
| **Real-Time Rendering (RTR)** ★★★ | Tomas Akenine-Möller | [Book](http://www.amazon.com/dp/1568814240) | 图形学圣经，第4版最新 |

### 1.2 学术教程

| 资源 | 机构 | 链接 |
|------|------|------|
| GPU Architecture Fundamentals | 爱丁堡大学 | [PDF](https://www.oldhomepage.inf.ed.ac.uk/~dts/pub/graphics/gpu-arch-fundamentals.pdf) |
| How GPUs Work | CMU | [PDF](http://www.cs.cmu.edu/afs/cs/academic/class/15869/f11/lectures/04_gpuarch.pdf) |
| Parallel Computer Architecture | CMU 15-418 | [Course](http://15418.courses.cs.cmu.edu/spring2016/) |
| Parallel Computing | Stanford CS149 | [Course](https://gfxcourses.stanford.edu/cs149/fall23) |

### 1.3 IHV 官方白皮书

**NVIDIA**:
| 代号 | 链接 | 核心特性 |
|------|------|---------|
| Fermi (2010) | [PDF](https://www.nvidia.com/content/PDF/fermi_white_papers/NVIDIA_Fermi_Compute_Architecture_Whitepaper.pdf) | 首代统一架构，PolyMorph Engine |
| Kepler (2012) | [PDF](https://www.nvidia.com/content/PDF/kepler/NVIDIA-Kepler-GK110-Architecture-Whitepaper.pdf) | Hyper-Q, Dynamic Parallelism |
| Maxwell (2014) | [PDF](https://www.nvidia.com/content/PDF/maxwell/NVIDIA_Maxwell_GM107_Whitepaper.pdf) | 高效能，SMM 设计 |
| Pascal (2016) | [PDF](https://images.nvidia.com/content/pdf/Pascal_Whitepaper_Final_9-26-16.pdf) | NVLink, FP16 |
| Volta (2017) | [PDF](https://images.nvidia.com/content/volta-architecture/pdf/volta-architecture-whitepaper.pdf) | Tensor Core, HBM2 |
| Turing (2018) | [PDF](https://images.nvidia.com/aem-dam/en-zz/Solutions/geforce/whitepapers/NVIDIA_TURING_Architecture_Whitepaper.pdf) | RT Core, Mesh Shader |
| Ampere (2020) | [PDF](https://images.nvidia.com/aem-dam/en-zz/Solutions/data-center/nvidia-ampere-architecture-whitepaper.pdf) |第二代 RT Core |
| Hopper (2022) | [PDF](https://resources.nvidia.com/en-us-tensor-core) | FP8, Transformer Engine |
| Blackwell (2024) | [PDF](https://nvdam.widen.net/s/wwns8rnjsz/blackwell-architecture-white-paper) | 第二代 Tensor Core, NVLink 5 |

**AMD**:
| 代号 | 链接 |
|------|------|
| RDNA 1 | [PDF](https://www.amd.com/system/files/documents/rdna-whitepaper.pdf) |
| RDNA 2 | [Web](https://www.amd.com/en/products/graphics/technologies/rdna-2.html) |
| RDNA 3 | [Web](https://www.amd.com/en/products/graphics/technologies/rdna-3.html) |
| CDNA | [PDF](https://www.amd.com/system/files/documents/amd-cdna-white-paper.pdf) |

**Intel**:
| 代号 | 链接 |
|------|------|
| Xe | [PDF](https://www.intel.com/content/dam/www/public/us/en/documents/technology-innovations/xe-architecture-brief.pdf) |

---

## 二、图形管线详解 🏆

### 2.1 API 官方文档

| API | 链接 | 说明 |
|-----|------|------|
| **Direct3D 11 Pipeline** | [MS Docs](https://learn.microsoft.com/en-us/windows/win32/direct3d11/overviews-direct3d-11-graphics-pipeline) | 最清晰的管线图 |
| **Direct3D 12 Pipeline** | [MS Docs](https://learn.microsoft.com/en-us/windows/win32/direct3d12/pipeline-stages) | 显式管线控制 |
| **OpenGL Pipeline** | [Khronos](https://www.khronos.org/opengl/wiki/Rendering_Pipeline_Overview) | Wiki 概览 |
| **Vulkan Pipeline** | [Khronos](https://www.khronos.org/vulkan) | 低开销 API |

### 2.2 IHV 管线文档

**NVIDIA** (Vulkan 相关):
| 文档 | 链接 |
|------|------|
| Vulkan Device-Generated Commands | [PDF](https://developer.nvidia.com/device-generated-commands-vulkan) |
| GPU-Driven Rendering | [PDF](http://on-demand.gputechconf.com/gtc/2016/presentation/s6138-christoph-kubisch-pierre-boudier-gpu-driven-rendering.pdf) |
| Vulkan Shader Resource Binding | [Blog](https://developer.nvidia.com/vulkan-shader-resource-binding) |
| Vulkan Memory Management | [Blog](https://developer.nvidia.com/vulkan-memory-management) |

**AMD** (Vulkan 相关):
| 文档 | 链接 |
|------|------|
| Vulkan barriers explained | [Blog](http://gpuopen.com/vulkan-barriers-explained/) |
| Vulkan Fast Paths | [PDF](https://gpuopen.com/wp-content/uploads/2016/03/VulkanFastPaths.pdf) |
| D3D12 & Vulkan: Lessons Learned | [PDF](https://gpuopen.com/wp-content/uploads/2016/03/d3d12_vulkan_lessons_learned.pdf) |
| Vulkan Renderpasses | [Blog](http://gpuopen.com/vulkan-renderpasses/) |

**Intel**:
| 文档 | 链接 |
|------|------|
| API without Secrets: Introduction to Vulkan | [Series](https://github.com/GameTechDev/IntroductionToVulkan) |

**Arm** (Mobile):
| 文档 | 链接 |
|------|------|
| Vulkan Best Practice for Mobile | [GitHub](https://github.com/ARM-software/vulkan_best_practice_for_mobile_developers) |
| Mali GPU Best Practices | [Guide](https://developer.arm.com/solutions/graphics/developer-guides/mali-gpu-best-practices) |

---

## 三、经典书籍 🏆

| 书籍 | 作者 | 链接 | 推荐度 |
|------|------|------|--------|
| **Real-Time Rendering 4th** | Akenine-Möller, Haines, Hoffman | [Amazon](http://www.amazon.com/dp/1568814240) | ★★★ 必备 |
| **GPU Gems** | NVIDIA | [Free Online](https://developer.nvidia.com/gpugems/GPUGems/) | ★★★ 免费 |
| **GPU Gems 2** | NVIDIA | [Free Online](https://developer.nvidia.com/gpugems/GPUGems2/) | ★★★ 免费 |
| **GPU Gems 3** | NVIDIA | [Free Online](https://developer.nvidia.com/gpugems/GPUGems3/) | ★★★ 免费 |
| **Computer Graphics: Principles and Practice** | Hughes et al. | [Amazon](http://www.amazon.com/dp/0321399528) | ★★ 基础 |
| **OpenGL Programming Guide (Red Book)** | Shreiner et al. | [Amazon](http://www.amazon.com/dp/0321773039) | ★★ API 参考 |
| **OpenGL Shading Language (Orange Book)** | Rost et al. | [Amazon](http://www.amazon.com/dp/0321637631) | ★★ Shader |
| **OpenGL Insights** | Cozzi, Riccio | [Amazon](http://www.amazon.com/dp/1439893764) | ★★ 高级 |

---

## 四、调试与性能分析工具

| 工具 | 链接 | 说明 |
|------|------|------|
| **RenderDoc** ★★★ | [GitHub](https://github.com/baldurk/renderdoc) | 跨平台帧调试器 |
| **NVIDIA Nsight** | [NVIDIA](https://developer.nvidia.com/nvidia-nsight-visual-studio-edition) | NVIDIA 官方 |
| **AMD CodeXL** | [GitHub](https://github.com/GPUOpen-Tools/CodeXL) | AMD 调试器 |
| **Intel GPA** | [Intel](https://software.intel.com/en-us/gpa) | Intel 分析器 |
| **apitrace** | [Site](http://apitrace.github.io) | API 跟踪工具 |
| **tracy** | [GitHub](https://github.com/wolfpld/tracy) | 实时帧分析器 |

---

## 五、在线学习平台

| 平台 | 链接 |
|------|------|
| Shadertoy | [https://www.shadertoy.com](https://www.shadertoy.com) |
| GLSL Sandbox | [http://glslsandbox.com](http://glslsandbox.com) |
| Scratchapixel | [https://www.scratchapixel.com](https://www.scratchapixel.com) |
| Learn OpenGL | [https://learnopengl.com](https://learnopengl.com) |

---

## 六、社区与论坛

| 社区 | 链接 |
|------|------|
| Reddit r/GraphicsProgramming | [https://www.reddit.com/r/GraphicsProgramming](https://www.reddit.com/r/GraphicsProgramming) |
| Reddit r/gpu | [https://www.reddit.com/r/gpu](https://www.reddit.com/r/gpu) |
| GDC Vault | [https://gdcvault.com](https://gdcvault.com) |
| SIGGRAPH | [https://www.siggraph.org](https://www.siggraph.org) |
| Khronos Forums | [https://community.khronos.org](https://community.khronos.org) |

---

## 七、推荐学习路径

### 初学者路径
1. **Real-Time Rendering** 第1-3章（概念）
2. **A Trip Through the Graphics Pipeline**（管线理解）
3. **Learn OpenGL** 教程（实践）
4. **GPU Gems** 系列（技术）

### 进阶路径
1. **NVIDIA/AMD 白皮书**（架构深入）
2. **Vulkan/DX12 官方文档**（现代 API）
3. **IHV 性能指南**（优化）
4. **GDC/SIGGRAPH 演讲**（前沿）

### 高级路径
1. **渲染管线实现**（自研引擎）
2. **GPU 架构分析**（性能瓶颈理解）
3. **前沿技术追踪**（SIGGRAPH/GDC）

---

---

## 八、Stack Overflow / Stack Exchange 高分问答 🏆

### 8.1 Computer Graphics Stack Exchange (Top Rated)

| 问题 | 链接 | 得分 |
|------|------|------|
| How can I debug GLSL shaders? | [Link](https://computergraphics.stackexchange.com/questions/96) | 72 |
| Should new graphics programmers be learning Vulkan instead of OpenGL? | [Link](https://computergraphics.stackexchange.com/questions/3575) | 69 |
| When is a compute shader more efficient than a pixel shader? | [Link](https://computergraphics.stackexchange.com/questions/54) | 63 |
| Albedo vs Diffuse | [Link](https://computergraphics.stackexchange.com/questions/350) | 56 |
| Sharp Corners with Signed Distance Fields Fonts | [Link](https://computergraphics.stackexchange.com/questions/306) | 54 |
| How is Gaussian Blur Implemented? | [Link](https://computergraphics.stackexchange.com/questions/39) | 53 |
| What is Importance Sampling? | [Link](https://computergraphics.stackexchange.com/questions/4979) | 45 |
| What is Ray Marching? Is Sphere Tracing the same thing? | [Link](https://computergraphics.stackexchange.com/questions/161) | 43 |
| What is a stencil buffer? | [Link](https://computergraphics.stackexchange.com/questions/12) | 41 |
| What is the cost of changing state? | [Link](https://computergraphics.stackexchange.com/questions/37) | 38 |

### 8.2 GPU 硬件相关高分问答

| 问题 | 链接 | 得分 |
|------|------|------|
| What does GPU assembly look like? | [Link](https://computergraphics.stackexchange.com/questions/7809) | 24 |
| In-depth analysis of the difference between CPU and GPU | [Link](https://stackoverflow.com/questions/7690230) | 12 |
| How is anisotropic filtering typically implemented in modern GPUs? | [Link](https://computergraphics.stackexchange.com/questions/1432) | 18 |
| Why do GPUs still have rasterizers? | [Link](https://computergraphics.stackexchange.com/questions/4062) | 14 |
| Why is work-efficiency desired in GPU programming? | [Link](https://computergraphics.stackexchange.com/questions/362) | 14 |
| How many polygons can modern hardware reach? | [Link](https://computergraphics.stackexchange.com/questions/1793) | 15 |
| Why do we have graphics frameworks like OpenGL and DirectX? | [Link](https://computergraphics.stackexchange.com/questions/2231) | 17 |

### 8.3 渲染管线相关高分问答

| 问题 | 链接 | 得分 |
|------|------|------|
| How does OpenGL work at the lowest level? | [Link](https://stackoverflow.com/questions/6399676) | 99 |
| Graphics driver "hello world" example? | [Link](https://stackoverflow.com/questions/27812098) | 31 |
| How are Direct3D and OpenGL instructions handled in a graphics card? | [Link](https://stackoverflow.com/questions/6352159) | 11 |
| What is GPU driven rendering? | [Link](https://stackoverflow.com/questions/59686151) | 8 |
| How does the graphics pipeline use shared memory? | [Link](https://stackoverflow.com/questions/13831772) | 2 |

### 8.4 CUDA / GPGPU 高分问答

| 问题 | 链接 | 得分 |
|------|------|------|
| How to get the CUDA version? | [Link](https://stackoverflow.com/questions/9727688) | 1013 |
| What is the canonical way to check for errors using CUDA runtime API? | [Link](https://stackoverflow.com/questions/14038589) | 318 |
| A top-like utility for monitoring CUDA activity on GPU | [Link](https://stackoverflow.com/questions/8223811) | 297 |
| What's the difference between CUDA and Shader? | [Link](https://gamedev.stackexchange.com/questions/136029) | 6 |

---

> 本清单整合自 GitHub awesome-opengl、awesome-vulkan、Stack Overflow、Computer Graphics Stack Exchange 及社区公认最佳资源