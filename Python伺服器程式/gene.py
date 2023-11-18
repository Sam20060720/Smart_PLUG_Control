from PIL import Image
import random

def place_trees(background_path, trunk_path, tree_path, leaves_with_flowers_path, height, width, num_trees_with_flowers):
    # 打开背景图像
    background = Image.open(background_path)
    background_width, background_height = background.size

    for _ in range(num_trees_with_flowers):
        # 随机选择樹的位置
        x = random.randint(0, width - 1)
        y = random.randint(height - 20, height - 1)

        # 打开樹幹、樹、葉子圖像
        trunk = Image.open(trunk_path)
        tree = Image.open(tree_path)
        leaves_with_flowers = Image.open(leaves_with_flowers_path)

        # 将樹幹、樹、葉子圖像合并到背景上
        background.paste(trunk, (x, y), trunk)
        background.paste(tree, (x, y - tree.size[1]), tree)
        background.paste(leaves_with_flowers, (x - 20, y - tree.size[1] - leaves_with_flowers.size[1]), leaves_with_flowers)

    # 返回包含樹的新圖像
    return background

# 使用示例
background_path = 'background.jpg'  # 背景圖片的路徑
trunk_path = 'trunk.png'            # 樹幹圖片的路徑
tree_path = 'tree.png'              # 有葉子的樹圖片的路徑
leaves_with_flowers_path = 'leaves_with_flowers.png'  # 葉子也有花的圖片的路徑
widget = 800  # 背景寬度
height = 600  # 背景高度
num_trees_with_flowers = 5  # 要放置的樹的數量

result_image = place_trees(background_path, trunk_path, tree_path, leaves_with_flowers_path, height, widget, num_trees_with_flowers)
result_image.save('result.jpg')  # 將結果保存為新圖片